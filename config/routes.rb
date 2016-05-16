Rails.application.routes.draw do
  root 'downloads#new'

  resources :downloads, only: [:new, :create, :show] do
    post :start, on: :member
    get :download, on: :member
  end
end
