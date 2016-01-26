Rails.application.routes.draw do
  root 'downloads#new'

  resources :downloads, only: [:new, :create, :show] do
    get :download, on: :member
  end
end
