Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Auth
      resources :sessions, only: [:create, :destroy]

      # Milestone 1 — Users, Properties, Rooms
      resources :users,      only: [:create, :update, :destroy, :index, :show]
      resources :properties, only: [:create, :update, :destroy, :index, :show] do
        get :documents, on: :member
      end
      resources :rooms, only: [:create, :update, :destroy, :index]

      # Milestone 1.5 — Lease Applications
      resources :lease_applications, only: [:create, :update, :destroy, :show, :index] do
        member { patch :validate }
      end
    end
  end
end
