Rails.application.routes.draw do
  root 'downloads#new'

  resources :downloads, only: [:new, :create, :show]
end
