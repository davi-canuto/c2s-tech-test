Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  
  root "dashboard#index"

  resources :emails, only: [:new, :create]
  resources :customers, only: [:index, :show]
  resources :parser_records, only: [:index, :show]
end
