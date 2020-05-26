Rails.application.routes.draw do
  root 'application#serve_single_page_app'

  post 'auth/saml_callback', to: 'sessions#create'
  get 'auth/failure', to: 'sessions#failure'

  get 'login', to: 'sessions#login'
  post 'login', to: 'sessions#login_creds'
  get 'logout', to: 'sessions#destroy'
  get 'unauthorized', to: 'sessions#unauthorized'
  get 'me', to: 'sessions#me'

  get 'health-check', to: 'health_checks#show'
  get 'help', to:'help#show'

  post 'increment_vva_coachmarks_status', to: 'downloads#increment_vva_coachmarks_status'

  if Rails.env.test?
    get 'test', to: 'test#index'
    post 'test/touch_file', to: 'test#touch_file'
    post 'test/download', to: 'test#download'
  end

  namespace :api do
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
      resources :document_counts, only: :index
    end
  end

  %w( 500 ).each do |code|
    get code, :to => "errors#show", :status_code => code
  end

  # all other routes sent to SPA
  match '(*path)' => 'application#serve_single_page_app', via: [:get]
end
