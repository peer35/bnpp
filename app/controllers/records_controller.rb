class RecordsController < ApplicationController
  require 'rsolr'
  require 'csv'

  before_action :set_record, only: [:show, :edit, :update, :destroy]

  include Blacklight::Configurable
  include Blacklight::Catalog

  include Pundit
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  before_action :set_paper_trail_whodunnit

  before_action :require_user_authentication_provider
  before_action :verify_user

  solr_config = Rails.application.config_for :blacklight
  @@solr = RSolr.connect :url => solr_config['url'] # get this from blacklight config

  def verify_user
    if action_name != 'export'
      if current_user.to_s.blank?
        flash[:notice] = I18n.t('admin.need_login') and raise Blacklight::Exceptions::AccessDenied
      elsif Rails.configuration.x.admin_users_email.include? current_user.email
      else
        raise Pundit::NotAuthorizedError
      end
    end
  end

  # GET /records
  # GET /records.json
  def index
    # In case the user clicks the search button on a Records page
    unless params[:q].nil?
      redirect_to :controller => 'catalog', action: "index", q: params[:q]
    end

    @records = Record.order('id ASC').all()
  end

  # GET /records/1
  # GET /records/1.json
  def show
  end

  # GET /records/new
  def new
    @record = Record.new
  end

  # GET /records/1/edit
  def edit
    @versions = @record.versions
    @current = @record
    @versionshowing = Hash.new()
    if params[:version]
      @record = @record.versions.find(params[:version]).reify
      @versionshowing['status'] = 'previous'
    else
      @versionshowing['status'] = 'current'
    end

    @versionshowing['created_by'] = @record.user_email
    @versionshowing['created_at'] = @record.updated_at
  end

  # POST /records
  # POST /records.json
  def create
    @record = Record.new(record_params)
    @record.user_email = current_user.email
    respond_to do |format|
      if @record.save
        format.html {redirect_to @record, notice: 'Record was successfully created.'}
        format.json {render :show, status: :created, location: @record}
      else
        format.html {render :new}
        format.json {render json: @record.errors, status: :unprocessable_entity}
      end
    end
  end

  # PATCH/PUT /records/1
  # PATCH/PUT /records/1.json
  def update
    respond_to do |format|
      @record.user_email = current_user.email
      if @record.update(record_params)
        add_to_solr(@record)
        #format.html {redirect_to @record, notice: 'Record was successfully updated.'}
        format.html {redirect_to :controller => 'catalog', action: "show", id: @record.id}
        format.json {render :show, status: :ok, location: @record}
      else
        format.html {render :edit}
        format.json {render json: @record.errors, status: :unprocessable_entity}
      end
    end
  end

  # DELETE /records/1
  # DELETE /records/1.json
  def destroy
    remove_from_solr(@record.id)
    @record.destroy
    respond_to do |format|
      format.html {redirect_to records_url, notice: 'Record was successfully destroyed.'}
      format.json {head :no_content}
    end
  end

  # POST /validate
  def validate
    parsed = {}
    if params[:type] == 'persoon'
      parsed = validate_personen(params[:teststr])
    elsif params[:type] == 'rest'
      parsed = validate_rest(params[:teststr])
    elsif params[:type] == 'verschenen'
      parsed[0] = parse_verschenen(params[:teststr])
    end
    render json: parsed
  end

  # GET /records/indexall
  def indexall
    #add all admins blocks to the solr index with the admin id
    #loop through admins
    respond_to do |format|
      Record.all.each do |record|
        add_to_solr(record)
      end
      flash[:notice] = 'Records reindexed.'
      format.html {redirect_to :controller => 'catalog', action: "index"}
    end
  end

  # GET /records/export
  def export
    exp={}
    time = Time.new
    exp['timestamp']=time.strftime("%Y-%m-%d %H:%M:%S")
    exp['note']='Export of BNPP data'
    exp['license']='http://creativecommons.org/licenses/by-nc-sa/4.0/'
    exp['developed by']='Peter Vos, University Library Vrije Universiteit. p.j.m.vos@vu.nl'
    exp['records']=[]
    Record.all.each do |record|
      exp['records'] = add_to_export(record, exp['records'])
    end
    render json: JSON.pretty_generate( exp.as_json )
  end

  private
  # parsers should be in the model
  def parse_persoon(val)
    val = val.gsub(/[´'‛’`‘`]/, "'")
    s = val.split(':')
    # commissie van redactie: J.D. Dengerink: 1 sep. 1953-4 nov. 1955 (1, nr. 1-3, nr. 9)
    if s.length == 2
      start = 0
    else
      start = 1
    end
    parsed = {'naam' => nil, 'rol' => nil, 'van' => nil, 'tot' => nil, 'nummers' => nil}
    /(?<naam>[A-Z](\p{L}|\.|-|'|’|\/|\s)+)(\s*\((?<rol>.+)\))*/ =~ s[start]
    parsed['naam'] = transpose_name(naam) if naam
    parsed['rol'] = rol

    if s.length > 1
      /.+?(?<van>\d{4})(-.*(?<tot>\d{4}))?(.*\((?<nummers>.+)\))?/ =~ s[start + 1]
      parsed['van'] = van
      parsed['tot'] = tot
      parsed['nummers'] = nummers
    end

    return parsed
  end

  def transpose_name(name)
    # Arry Zel- denrust
    n = name.strip()
    n = n.gsub('- ', '')
    #A.Pek
    n = n.gsub(/(.+)\.([A-Z]\p{L}+)/, '\1. \2') # Nu maar hopen dat er geen achternamen beginnen met een diakriet in de hoofdletter
    # W.J.G. Gooyens
    # L.R.M. Marijs
    # T. Muit
    n = n.gsub(/^(\S+)(.*?)([A-Z]\p{L}+.*)/, '\3, \1\2').strip()
    return n
  end

  def validate_personen(teststr)
    list = []
    teststr.split(';').each do |p|
      list.append(parse_persoon(p))
    end
    return list
  end


  def parse_personen_solr(red, med)
    list = []
    red.split(';').each do |p|
      n = parse_persoon(p)['naam']
      if n
        list.append(n) unless list.include?(n)
      end
    end
    med.split(';').each do |p|
      n = parse_persoon(p)['naam']
      if n
        list.append(n) unless list.include?(n)
      end
    end
    return list
  end

  def parse_rest(value)
    # met dubbele punt?
    parsed = {'value' => nil, 'van' => nil, 'tot' => nil}
    arr = value.split(':')
    if arr.length == 1
      val = arr[0].strip()
    elsif arr.length == 2
      val = arr[1].strip()
      # starts with date
      m = arr[0].scan(/\d{4}/)
      if m.length > 1
        parsed['van'] = m[0]
        parsed['tot'] = m[1]
      elsif m.length == 1
        parsed['van'] = m[0]
      end
    else
      val = value
    end

    #@ ' sGravenhage4's Gravenhage3's Gravenhage351's Gravenhage (uitgaveadressen NoordAmerika niet vermeld)1's Gravenhage,1
    # Veenen-daal
    val = val.gsub('- en', '+ en') # koppelteken niet weghalen in boek- en tijdschriftuitgever
    val = val.gsub(/[´'‛’`‘`]/, "'") # vervang alle rare apostrof variaties
    val = val.gsub(/^'s-/, '\'s ') # 's-Gravenhage -> 's Gravenhage
    val = val.gsub(/^'sG/, '\'s G') # 'sGravenhage -> 's Gravenhage
    val = val.gsub(/-/, '')
    val = val.gsub(/–/, '-') # vervang unicode - teken door gewone
    val = val.gsub('+ en', '- en')
    val = val.gsub(/(^,+)|(,+$)/, '') # geen komma aan begin en eind
    val = val.gsub(/\s{2,}/, ' ') # dubbele spaties
    parsed['value'] = val.strip()
    return parsed
  end

  def parse_verschenen(val)
    # "jul. 1982-heden= jan. 1993"
    # mogelijk mis ik hier wat variaties
    parsed = {'van' => '3000', 'tot' => '3000'}
    m = val.scan(/\d{4}/)
    if m.length > 1
      parsed['van'] = m[0]
      parsed['tot'] = m[1]
    elsif m.length == 1
      parsed['van'] = m[0]
      parsed['tot'] = m[0]
    end
    return parsed
  end

  def validate_rest(val)
    list = []
    a = val.split(';')
    for val in a
      value = parse_rest(val)
      value == '' ? list.append('-') : list.append(value)
    end
    return list
  end

  def parse_rest_solr(val)
    list = []
    a = val.split(';')
    for val in a
      value = parse_rest(val)['value']
      value == '' ? list.append('-') : list.append(value)
    end
    return list
  end

  def parse_categorie(c)
    cats = parse_roman(c)
    categories = []
    for cat in cats
      categories.append('I nieuws (dag-, week- en opiniebladen)') if cat == 'I'
      categories.append('II cultuur en recreatie') if cat == 'II'
      categories.append('III kerkelijk en godsdienstig leven') if cat == 'III'
      categories.append('IV opvoeding en onderwijs') if cat == 'IV'
      categories.append('V politiek, stand- en vakorganisaties') if cat == 'V'
    end
    return categories
  end

  def parse_omvang(c)
    cats = parse_roman(c)
    categories = []
    for cat in cats
      categories.append('I <100 pag.') if cat == 'I'
      categories.append('II 100-200 pag.') if cat == 'II'
      categories.append('III 200-300 pag.') if cat == 'III'
      categories.append('IV 300-400 pag.') if cat == 'IV'
      categories.append('V 400-500 pag.') if cat == 'V'
      categories.append('VI >500 pag.') if cat == 'VI'
    end
    return categories
  end

  def parse_roman(c)
    cat = []
    cat.append('I') if c =~ /(?<!V)(?<!I)I(?!I)(?!V)/
    cat.append('II') if c =~ /(?<!I)II(?!I)/
    cat.append('III') if c =~ /III/
    cat.append('IV') if c =~ /IV/
    cat.append('V') if c =~ /(?<!I)V(?!I)/
    cat.append('VI') if c =~ /VI/
    return cat
  end

  def parse_autopsie(a)
    list = []
    m = a.scan(/(?![CXI])[A-Z]{3,}|KB|PM|GA|IIAV|IAAV|IIMA|IISG|RA|Smits|UvA|Mulock|RULi/)
    for org in m
      list.append(org) unless list.include?(org)
    end
    return list
  end

  def add_to_export(record, exp)
    p = parse_verschenen(record.verschenen)
    dtr = '[%s TO %s]' % [p['van'], p['tot']]

    exp.append(:id => record.id,
               :titel_s => record.titel,
               :ondertitelc_s => record.ondertitel,
               :ondertitel_sm => parse_rest_solr(record.ondertitel),
               :categorie_s => record.categorie, :categorie_sm => parse_categorie(record.categorie),
               :verschenen_s => record.verschenen, :verschenen_dtr => dtr, :pub_date => p['van'],
               :eigenaarc_s => record.eigenaar, :eigenaar_sm => parse_rest_solr(record.eigenaar),
               :uitgeverc_s => record.uitgever, :uitgever_sm => parse_rest_solr(record.uitgever),
               :drukkerc_s => record.drukker, :drukker_sm => parse_rest_solr(record.drukker),
               :uitgavec_s => record.uitgave, :uitgave_sm => parse_rest_solr(record.uitgave),
               :frequentie_s => record.frequentie,
               :omvang_s => record.omvang, :omvang_sm => parse_omvang(record.omvang),
               :formaat_s => record.formaat,
               :oplage_s => record.oplage,
               :prijzen_s => record.prijzen,
               :fotos_s => record.fotos,
               :tekeningen_s => record.tekeningen,
               :redactiec_s => record.redactie,
               :medewerkersc_s => record.medewerkers,
               :personen_sm => parse_personen_solr(record.redactie, record.medewerkers),
               :speciale_s => record.speciale,
               :biblio_s => record.biblio,
               :autopsie_s => record.autopsie, :autopsie_sm => parse_autopsie(record.autopsie),
               :achtergrond_s => record.achtergrond, :achtergrond_sm => record.achtergrond.split('/'),
               :literatuur_s => record.literatuur,
               :vindplaats_s => record.vindplaats)
    return exp
  end

  def remove_stop_words(value)
    value=value.gsub(/^(d|D)e\s/,'')
    value=value.gsub(/^(h|H)et\s/,'')
    value=value.gsub(/^(e|E)en\s/,'')
    return value
  end

  def remove_from_solr(id)
    @@solr.delete_by_id(id)
  end

  def add_to_solr(record)
    p = parse_verschenen(record.verschenen)
    dtr = '[%s TO %s]' % [p['van'], p['tot']]

    @@solr.add :id => record.id,
               #:titel_sort => remove_stop_words(record.titel),
               :titel_sort => record.titel,
               :titel_s => record.titel,
               :ondertitelc_s => record.ondertitel,
               :ondertitel_sm => parse_rest_solr(record.ondertitel),
               :categorie_s => record.categorie, :categorie_sm => parse_categorie(record.categorie),
               :verschenen_s => record.verschenen, :verschenen_dtr => dtr, :pub_date => p['van'],
               :eigenaarc_s => record.eigenaar, :eigenaar_sm => parse_rest_solr(record.eigenaar),
               :uitgeverc_s => record.uitgever, :uitgever_sm => parse_rest_solr(record.uitgever),
               :drukkerc_s => record.drukker, :drukker_sm => parse_rest_solr(record.drukker),
               :uitgavec_s => record.uitgave, :uitgave_sm => parse_rest_solr(record.uitgave),
               :frequentie_s => record.frequentie,
               :omvang_s => record.omvang, :omvang_sm => parse_omvang(record.omvang),
               :formaat_s => record.formaat,
               :oplage_s => record.oplage,
               :prijzen_s => record.prijzen,
               :fotos_s => record.fotos,
               :tekeningen_s => record.tekeningen,
               :redactiec_s => record.redactie,
               :medewerkersc_s => record.medewerkers,
               :personen_sm => parse_personen_solr(record.redactie, record.medewerkers),
               :speciale_s => record.speciale,
               :biblio_s => record.biblio,
               :autopsie_s => record.autopsie, :autopsie_sm => parse_autopsie(record.autopsie),
               :achtergrond_s => record.achtergrond, :achtergrond_sm => record.achtergrond.split('/'),
               :literatuur_s => record.literatuur,
               :vindplaats_s => record.vindplaats
    @@solr.commit

  end

  # Use callbacks to share common setup or constraints between actions.
  def set_record
    @record = Record.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def record_params
    params.require(:record).permit(:bnpp_id, :titel, :ondertitel, :categorie, :verschenen, :eigenaar, :uitgever,
                                   :drukker, :uitgave, :frequentie, :omvang, :formaat, :oplage, :prijzen, :fotos,
                                   :tekeningen, :redactie, :medewerkers, :speciale, :biblio, :autopsie, :achtergrond,
                                   :literatuur, :vindplaats)
  end
end



