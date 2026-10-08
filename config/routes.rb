Rails.application.routes.draw do
  root "lists#index"
  get "login", to: "sessions#new", as: :login
  resource :session
  resources :passwords, param: :token
  resource :registration, only: [ :new, :create ]
  resource :search, only: :show
  resource :push_subscription, only: [ :create, :destroy ]
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  resource :account, only: [ :edit, :update ] do
    patch :time_zone, action: :detect_time_zone
    resources :sessions, only: :destroy, module: :account do
      delete :others, on: :collection, action: :destroy_others
    end
  end
  resources :lists do
    get :archived, on: :collection
    member do
      get :stats
      post :add_user
      post :archive
      post :unarchive
      post :duplicate
      get "completed/:year", to: "lists#completed_year", as: :completed_year
    end
    resources :tasks, only: [ :create ]
    resources :categories, only: [ :create, :update, :destroy ] do
      patch :make_default, on: :member
    end
    resources :invitations, only: :destroy do
      post :resend, on: :member
    end
    resources :memberships, only: :destroy do
      patch :transfer, on: :member
    end
  end
  resources :tasks, only: [ :destroy, :edit, :update ] do
    collection do
      patch :sort
      post :restore
    end
    patch :move, on: :member
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "about", to: "pages#about"
  get "shortcuts", to: "pages#shortcuts"

  get "up" => "rails/health#show", as: :rails_health_check

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"
end
