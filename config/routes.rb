Rails.application.routes.draw do
  root "lists#index"
  get "login", to: "sessions#new", as: :login
  resource :session
  resources :passwords, param: :token
  resource :registration, only: [ :new, :create ]
  resource :account, only: [ :edit, :update ]
  resources :lists do
    member do
      get :snoozed
      post :add_user
      get "completed/:year", to: "lists#completed_year", as: :completed_year
    end
    resources :tasks, only: [ :create ]
    resources :categories, only: [ :create, :update, :destroy ]
  end
  resources :tasks, only: [ :destroy, :edit, :update ] do
    collection do
      patch :sort
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
