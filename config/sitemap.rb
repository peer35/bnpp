# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://bnpp.hdc.vu.nl"

SitemapGenerator::Sitemap.create do
  # We set a boolean value in our environment files to prevent generation in staging or development
  #break unless Rails.application.config.sitemap[:generate]

  # Add static pages
  # This is quite primitive - could perhaps be improved by querying the Rails routes in the about namespace
  ['', 'data'].each do |page|
    add "/#{page}"
  end

  # Add single record pages
  cursorMark = '*'
  solr = RSolr.connect :url => 'http://127.0.0.1:8983/solr/bnpp'

  loop do
    response = solr.get('select', :params => { # you may need to change the request handler
                                                                           'q'          => '*:*', # all docs
                                                                           'fl'         => 'id', # we only need the ids
                                                                           'fq'         => '', # optional filter query
                                                                           'cursorMark' => cursorMark, # we need to use the cursor mark to handle paging
                                                                           'rows'       => 1000,
                                                                           'sort'       => 'id asc'
    })

    response['response']['docs'].each do |doc|
      add "/catalog/#{doc['id']}"
      puts doc['id']
    end

    break if response['nextCursorMark'] == cursorMark # this means the result set is finished

    cursorMark = response['nextCursorMark']
  end
end