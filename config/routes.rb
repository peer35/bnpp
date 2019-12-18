Rails.application.routes.draw do
  
  resources :records
  mount Blacklight::Engine => '/'
  mount BlacklightAdvancedSearch::Engine => '/'

  Blacklight::Marc.add_routes(self)
  root to: "catalog#index"
    concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  devise_for :users
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  get '/about' => 'pages#about'
  get '/data' => 'pages#data', :as => 'data' # the :as generates method data_path

  post '/validate' => 'records#validate'
  get '/validate' => 'records#validate'

  resource :records do
    get 'record/indexall' => 'records#indexall'
    get 'record/export' => 'records#export'
  end

end
