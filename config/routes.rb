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

  get '/stats(/:interval)', to: 'stats#show', as: 'stats'
end
