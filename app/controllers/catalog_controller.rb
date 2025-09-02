# frozen_string_literal: true
class CatalogController < ApplicationController
  #include BlacklightAdvancedSearch::Controller
  include Blacklight::Catalog  #include Blacklight::Marc::Catalog

 
  layout :determine_layout if respond_to? :layout

  configure_blacklight do |config|
    # default advanced config values
    #config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    #config.advanced_search[:url_key] ||= 'advanced'
    #config.advanced_search[:query_parser] ||= 'edismax'
    #config.advanced_search[:form_solr_parameters] ||= {}

    config.advanced_search.enabled = true
    
    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    config.search_builder_class = ::SearchBuilder
    #

    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
        rows: 10

    }
    #config.spell_max=10

    config.add_field_configuration_to_solr_request! # for highlighting

    config.index.respond_to.docx = true


    # solr path which will be added to solr base url before the other solr params.
    #config.solr_path = 'select'

    # items to show per page, each number in the array represent another option to choose from.
    #config.per_page = [10,20,50,100]

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SearchHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    config.default_document_solr_params = {
        qt: 'document',
        ## These are hard-coded in the blacklight 'document' requestHandler
        fl: '*',
        rows: 1,
        q: '{!term f=id v=$id}'
    }

    # solr field configuration for search results/index views
    config.index.title_field = 'titel_s'
    config.index.display_type_field = 'format'
    #config.index.thumbnail_field = 'thumbnail_path_ss'

    # solr field configuration for document/show views
    #config.show.title_field = 'title_display'
    #config.show.display_type_field = 'format'
    #config.show.thumbnail_field = 'thumbnail_path_ss'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #
    # set :index_range to true if you want the facet pagination view to have facet prefix-based navigation
    #  (useful when user clicks "more" on a large facet and wants to navigate alphabetically across a large set of results)
    # :index_range can be an array or range of prefixes that will be used to create the navigation (note: It is case sensitive when searching values)

    # config.add_facet_field 'format', label: 'Format'
    # config.add_facet_field 'pub_date', label: 'Publication Year', single: true
    # config.add_facet_field 'subject_topic_facet', label: 'Topic', limit: 20, index_range: 'A'..'Z'
    # config.add_facet_field 'language_facet', label: 'Language', limit: true
    # config.add_facet_field 'lc_1letter_facet', label: 'Call Number'
    # config.add_facet_field 'subject_geo_facet', label: 'Region'
    # config.add_facet_field 'subject_era_facet', label: 'Era'

    # config.add_facet_field 'example_pivot_field', label: 'Pivot Field', :pivot => ['format', 'language_facet']

    # config.add_facet_field 'example_query_facet_field', label: 'Publish Date', :query => {
    # :years_5 => { label: 'within 5 Years', fq: "pub_date:[#{Time.zone.now.year - 5 } TO *]" },
    # :years_10 => { label: 'within 10 Years', fq: "pub_date:[#{Time.zone.now.year - 10 } TO *]" },
    # :years_25 => { label: 'within 25 Years', fq: "pub_date:[#{Time.zone.now.year - 25 } TO *]" }
    # }

    config.add_facet_field 'personen_sm', label: 'Persoon', sort: 'count', limit: 10, index_range: 'A'..'Z'
    config.add_facet_field 'uitgave_sm', label: 'Plaats van Uitgave', sort: 'count', limit: 10, index_range: 'A'..'Z'
    config.add_facet_field 'uitgever_sm', label: 'Uitgever', sort: 'count', limit: 10, index_range: 'A'..'Z'
    config.add_facet_field 'eigenaar_sm', label: 'Eigenaar', sort: 'count', limit: 10, index_range: 'A'..'Z'
    config.add_facet_field 'autopsie_sm', label: 'Autopsie', sort: 'count', limit: 10, index_range: 'A'..'Z'
    config.add_facet_field 'categorie_sm', label: 'Categorie', limit: true, sort: 'index'
    config.add_facet_field 'omvang_sm', label: 'Omvang per jaargang', limit: true, sort: 'index'
    #config.add_facet_field 'achtergrond_sm', label: 'Achtergrond', limit: true


    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'ondertitelc_s', label: 'Ondertitel', :highlight => true
    config.add_index_field 'eigenaarc_s', label: 'Eigenaar'
    config.add_index_field 'verschenen_s', label: 'Verschenen'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    # config.add_show_field 'title_display', label: 'Title'
    #config.add_show_field 'titel_s', label:'Titel'
    config.add_show_field 'ondertitelc_s', label: 'Ondertitel', :helper_method => :linebreak_helper
    config.add_show_field 'categorie_s', label: 'Categorie', :helper_method => :linebreak_helper
    config.add_show_field 'verschenen_s', label: 'Verschenen', :helper_method => :linebreak_helper
    config.add_show_field 'eigenaarc_s', label: 'Eigenaar', :helper_method => :linebreak_helper
    config.add_show_field 'uitgeverc_s', label: 'Uitgever', :helper_method => :linebreak_helper
    config.add_show_field 'drukkerc_s', label: 'Drukker', :helper_method => :linebreak_helper
    config.add_show_field 'uitgavec_s', label: 'Plaats van Uitgave', :helper_method => :linebreak_helper
    config.add_show_field 'frequentie_s', label: 'Frequentie', :helper_method => :linebreak_helper
    config.add_show_field 'omvang_s', label: 'Omvang', :helper_method => :linebreak_helper
    config.add_show_field 'formaat_s', label: 'Formaat', :helper_method => :linebreak_helper
    config.add_show_field 'oplage_s', label: 'Oplage', :helper_method => :linebreak_helper
    config.add_show_field 'prijzen_s', label: 'Prijzen', :helper_method => :linebreak_helper
    config.add_show_field 'fotos_s', label: 'Foto\'s', :helper_method => :linebreak_helper
    config.add_show_field 'tekeningen_s', label: 'Tekeningen', :helper_method => :linebreak_helper
    config.add_show_field 'redactiec_s', label: 'Redactie', :helper_method => :linebreak_helper
    config.add_show_field 'medewerkersc_s', label: 'Medewerkers', :helper_method => :linebreak_helper
    config.add_show_field 'speciale_s', label: 'Speciale nummers', :helper_method => :linebreak_helper
    config.add_show_field 'biblio_s', label: 'Bibliografische gegevens', :helper_method => :vv_helper
    config.add_show_field 'autopsie_s', label: 'Autopsie', :helper_method => :linebreak_helper
    config.add_show_field 'achtergrond_s', label: 'Achtergrond', :helper_method => :linebreak_helper
    config.add_show_field 'literatuur_s', label: 'Literatuur', :helper_method => :linebreak_helper
    config.add_show_field 'vindplaats_s', label: 'Vindplaats', :helper_method => :linebreak_helper
    config.add_show_field 'bnpp_s', label: 'In BNPP'


    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    config.add_search_field 'all_fields', label: 'Alle Velden'


    # # Now we see how to over-ride Solr request handler defaults, in this
    # # case for a BL "search field", which is really a dismax aggregate
    # # of Solr search fields.

    # config.add_search_field('title') do |field|
    # # solr_parameters hash are sent to Solr as ordinary url query params.
    # field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

    # # :solr_local_parameters will be sent using Solr LocalParams
    # # syntax, as eg {! qf=$title_qf }. This is neccesary to use
    # # Solr parameter de-referencing like $title_qf.
    # # See: http://wiki.apache.org/solr/LocalParams
    # field.solr_local_parameters = {
    # qf: '$title_qf',
    # pf: '$title_pf'
    # }
    # end

    config.add_search_field('personen_sm', label: 'Personen') do |field|
      field.solr_parameters = {
          :'spellcheck.dictionary' => 'personen',
          qf: '${personen_qf}',
          pf: '${personen_pf}'
      }
    end

    config.add_search_field('titel_s', label: 'Titel') do |field|
      field.solr_parameters = {
          :'spellcheck.dictionary' => 'titel',
          qf: '${titel_qf}',
          pf: '${titel_pf}'
      }
    end

    config.add_search_field('eigenaar_s', label: 'Eigenaar') do |field|
      field.solr_parameters = {
          :'spellcheck.dictionary' => 'eigenaar',
          qf: '${eigenaar_qf}',
          pf: '${eigenaar_pf}'
      }
    end

    config.add_search_field('verschenen_dtr', label: 'Jaar') do |field|
      field.solr_parameters = {
          qf: '${verschenen_qf}',
          pf: '${verschenen_pf}'
      }
    end

    # # Specifying a :qt only to show it's possible, and so our internal automated
    # # tests can test it. In this case it's the same as
    # # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    # config.add_search_field('subject') do |field|
    # field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
    # field.qt = 'search'
    # field.solr_local_parameters = {
    # qf: '$subject_qf',
    # pf: '$subject_pf'
    # }
    # end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    #config.add_sort_field 'score desc, pub_date_sort desc, titel_sort asc', label: 'relevance'
    config.add_sort_field 'score desc, titel_sort asc', label: 'relevantie'
    config.add_sort_field 'titel_sort asc', label: 'titel'
    config.add_sort_field 'pub_date_sort asc, titel_sort asc', label: 'jaar (oplopend)'
    config.add_sort_field 'pub_date_sort desc, titel_sort asc', label: 'jaar (aflopend)'


    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = true
    config.autocomplete_path = 'suggest'

    config.add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)

    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)

    config.add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    #config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
    #config.add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
    #config.add_show_tools_partial(:citation)

    config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')

    #config.advanced_search[:enabled] = true
  end
end
