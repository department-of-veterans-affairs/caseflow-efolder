Rails.application.routes.draw do
  root 'downloads#new'

  post 'auth/saml_callback', to: 'sessions#create'

  get 'login', to: 'sessions#create'
  get 'logout', to: 'sessions#destroy'
  get 'unauthorized', to: 'sessions#unauthorized'

  get 'health-check', to: 'health_checks#show'
  get 'help', to:'help#show'

  post 'increment_vva_coachmarks_status', to: 'downloads#increment_vva_coachmarks_status'

  resources :downloads, only: [:new, :create, :show] do
    post :start, on: :member
    post :retry, on: :member
    get :download, on: :member
    get :progress, on: :member

    # test user download delete route
    if ENV['TEST_USER_ID']
      post :delete, on: :member
    end
  end

  namespace :api do
    namespace :v1 do
      resources :documents, only: :show
      resources :files, only: :index
    end

    namespace :v2 do
      namespace :manifests, only: [] do
        post "/", action: :start
        post "/:id", action: :refresh
        get :history
        get "/:id", action: :progress
        get "/:id/document_count", action: :document_count
      end
      resources :manifests, only: [] do
        post :files_downloads, to: "files_downloads#start"
        get :files_downloads, to: "files_downloads#progress"
        get :zip, to: "files_downloads#zip"
      end
      resources :records, only: :show, param: :version_id
      resources :veterans, only: :index
    end
  end

  get '/stats(/:interval)', to: 'stats#show', as: 'stats'

  %w( 500 ).each do |code|
    get code, :to => "errors#show", :status_code => code
  end

  match '(*path)' => 'application#serve_single_page_app', via: [:get]
end
