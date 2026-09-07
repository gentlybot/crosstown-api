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
      end
    end
  end
end
