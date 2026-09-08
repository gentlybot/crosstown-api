require "sidekiq/web"

Rails.application.routes.draw do
  # Ops-only in spirit. No auth in development, like the original.
  mount Sidekiq::Web => "/sidekiq"

  get "up" => "rails/health#show", as: :rails_health_check
  get "api/health" => "rails/health#show"

  namespace :api do
    namespace :v1 do
      resource :session, only: %i[create destroy]
      resource :me, only: :show, controller: :me

      namespace :merchant, module: :merchant_area do
        resources :batches, only: %i[index show create]
        resources :routes, only: :index do
          post :build, on: :collection
        end
      end

      namespace :admin, module: :admin_area do
        resources :batches, only: %i[index show]
        resources :merchants, only: :index
        resources :routes, only: %i[index show] do
          post :build, on: :collection
          post :offer, on: :member
        end
      end

      namespace :courier, module: :courier_area do
        resource :availability, controller: "availability", only: %i[show update]
        resources :offers, only: :index do
          post :accept, on: :member
          post :decline, on: :member
        end
        resources :routes, only: %i[index show] do
          post :start, on: :member
          resources :stops, only: :update
        end
      end
    end
  end
end
