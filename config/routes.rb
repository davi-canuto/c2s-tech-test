Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#index"

  resources :emails, only: [ :new, :create ] do
    member do
      post :reprocess
    end
  end
  resources :customers, only: [ :index, :show, :destroy ]
  resources :parser_records, only: [ :index, :show ]
  resources :medias, only: [ :index, :show ]
end
