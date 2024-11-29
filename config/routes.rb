Rails.application.routes.draw do
  root "buckets#index"

  resource :account do
    scope module: :accounts do
      resource :join_code
      resources :users
    end
  end

  resolve "Bubble" do |bubble, options|
    route_for :bucket_bubble, bubble.bucket, bubble, options
  end

  resources :bubbles

  resources :buckets do
    resources :bubbles do
      resources :boosts
      resources :comments

      scope module: :bubbles do
        resource :image
        resource :pop
        resource :stage_picker
        resources :stagings
      end

      namespace :assignments, as: :assignment do
        resources :toggles
      end

      namespace :taggings, as: :tagging do
        resources :toggles
      end
    end
  end

  resources :filters
  resource :first_run
  resource :session

  resources :uploads, only: :create
  get "/u/*slug" => "uploads#show", as: :upload

  resources :users do
    scope module: :users do
      resource :avatar
    end
  end

  resources :workflows do
    resources :stages, module: :workflows
  end

  get "join/:join_code", to: "users#new", as: :join
  post "join/:join_code", to: "users#create"
  get "up", to: "rails/health#show", as: :rails_health_check
end
