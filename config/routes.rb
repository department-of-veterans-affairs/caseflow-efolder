Rails.application.routes.draw do
  root 'downloads#new'

  post 'auth/saml_callback', to: 'sessions#create'

  get 'login', to: 'sessions#create'
  get 'logout', to: 'sessions#destroy'
  get 'unauthorized', to: 'sessions#unauthorized'

  resources :downloads, only: [:new, :create, :show] do
    post :start, on: :member
    get :download, on: :member
    get :progress, on: :member
  end
end
