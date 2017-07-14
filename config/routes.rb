Rails.application.routes.draw do
  root 'downloads#new'

  post 'auth/saml_callback', to: 'sessions#create'

  get 'login', to: 'sessions#create'
  get 'logout', to: 'sessions#destroy'
  get 'unauthorized', to: 'sessions#unauthorized'

  get 'health-check', to: 'health_checks#show'
  get 'help', to:'help#show'

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
      resources :files, only: :show
    end
  end

  get '/stats(/:interval)', to: 'stats#show', as: 'stats'

  require "sidekiq/web"
  require "sidekiq/cron/web"
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    # Protect against timing attacks:
    # - See https://codahale.com/a-lesson-in-timing-attacks/
    # - See https://thisdata.com/blog/timing-attacks-against-string-comparison/
    # - Use & (do not use &&) so that it doesn't short circuit.
    # - Use digests to stop length information leaking (see also ActiveSupport::SecurityUtils.variable_size_secure_compare)
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_USERNAME"])) &
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_PASSWORD"]))
  end
  mount Sidekiq::Web, at: "/sidekiq"

end
