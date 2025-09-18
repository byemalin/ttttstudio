Rails.application.routes.draw do
  get 'pages/landing'
  # devise_for :users
  devise_for :users, controllers: { registrations: 'users/registrations' }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html


  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "pages#landing"

  get 'durak', to: 'pages#durak'

  resources :posts
  resources :takes

  get 'landing', to: 'pages#landing'

  # Adding route to show posts associated with 1 user:
  resources :users, only: [:show] do
    member do
      get 'posts', to: 'posts#user_posts'
    end
  end

end
