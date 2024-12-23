Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  namespace :api do
    namespace :v1 do
      resources :sleep_records, only: %i[index] do
        post :clock_in, on: :collection
        post :clock_out, on: :collection
        get :followings, on: :collection, to: "sleep_records#following_sleep_records"
      end

      post "follow/:target_user_id" => "follows#follow"
      post "unfollow/:target_user_id" => "follows#unfollow"
    end
  end
end
