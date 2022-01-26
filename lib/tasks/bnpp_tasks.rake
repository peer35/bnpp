namespace :bnpp_tasks do
  desc "TODO"
  task export: :environment do
    app = ActionDispatch::Integration::Session.new(Rails.application)
    app.get "/records/record/export"
  end
  task index: :environment do
    $VERBOSE = nil

    solr_config = Rails.application.config_for :blacklight
    class_variable_set(:@@solr, RSolr.connect(:url => solr_config['url'])) # get this from blacklight config

    #TODO move this shit to the model
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

    def validate_categorie(val)
      list=[]
      cats=parse_categorie(val)
      for val in cats
        logger.debug val
        list.append({'value' => val})
      end
      return list
    end

    def validate_omvang(val)
      list=[]
      cats=parse_omvang(val)
      for val in cats
        logger.debug val
        list.append({'value' => val})
      end
      return list
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
    n = Record.count
    Record.all.each do |record|
      puts n
      add_to_solr(record)
      n = n - 1
    end
  end
end
