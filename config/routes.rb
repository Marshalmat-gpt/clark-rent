Rails.application.routes.draw do
  # Sidekiq Web UI (admin-protected via HTTP basic auth)
  require 'sidekiq/web'

  if ENV['SIDEKIQ_WEB_USERNAME'].present? && ENV['SIDEKIQ_WEB_PASSWORD'].present?
    Sidekiq::Web.use(Rack::Auth::Basic) do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(username, ENV.fetch('SIDEKIQ_WEB_USERNAME')) &
        ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch('SIDEKIQ_WEB_PASSWORD'))
    end
  end

  mount Sidekiq::Web => '/admin/sidekiq'

  # Health check — utilisé par Railway (railway.toml healthcheckPath)
  get '/health', to: 'health#show'

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

      # Milestone 2.5 — Loyers et paiements
      resources :rent_payments, only: [:create, :index, :show] do
        member { patch :mark_paid }
      end

      # Milestone 2 — Leases + Applications
      resources :leases, only: [:create, :update, :destroy, :index, :show] do
        member { patch :terminate }
      end
      resources :lease_applications, only: [:create, :update, :destroy, :show, :index] do
        member { patch :validate }
      end

      # Milestone 3 — AI agent layer
      namespace :agent do
        post 'chat',                  to: 'chat#create'
        get  'context',               to: 'context#show'
        get  'properties/summary',    to: 'properties#summary'
        get  'leases/:id/irl',        to: 'leases#irl'
        post 'receipts',              to: 'receipts#create'
        get  'documents/:type',       to: 'documents#show'
        post 'notifications/send',    to: 'notifications#dispatch_message'
        resources :tickets, only: [:index, :create, :show] do
          member { patch :resolve }
        end
      end
    end
  end
end
