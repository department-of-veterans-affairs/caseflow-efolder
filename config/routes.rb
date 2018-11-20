Rails.application.routes.draw do
  root 'application#serve_single_page_app'

  post 'auth/saml_callback', to: 'sessions#create'

  get 'login', to: 'sessions#create'
  get 'logout', to: 'sessions#destroy'
  get 'unauthorized', to: 'sessions#unauthorized'

  get 'health-check', to: 'health_checks#show'
  get 'help', to:'help#show'

  post 'increment_vva_coachmarks_status', to: 'downloads#increment_vva_coachmarks_status'

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
      end
      resources :manifests, only: [] do
        post :files_downloads, to: "files_downloads#start"
        get :files_downloads, to: "files_downloads#progress"
        get :zip, to: "files_downloads#zip"
      end
      resources :records, only: :show, param: :version_id
    end
  end

  get '/stats(/:interval)', to: 'stats#show', as: 'stats'

  %w( 500 ).each do |code|
    get code, :to => "errors#show", :status_code => code
  end

  match '(*path)' => 'application#serve_single_page_app', via: [:get]
end
