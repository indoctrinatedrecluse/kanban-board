Rails.application.routes.draw do
  root "boards#show"

  resource :board, only: [:show, :edit, :update] do
    post :clear, on: :member
  end
  resources :columns, only: [:show, :update] do
    resources :cards, only: :create
  end
  resources :cards, only: [:show, :update, :destroy] do
    patch :move, on: :member
    post :duplicate, on: :member
  end

  get "up" => "rails/health#show", as: :rails_health_check
end