Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Auth
      resources :sessions, only: [:create, :destroy]

      # Milestone 1 — CRUD de base
      resources :users,      only: [:create, :update, :destroy, :index, :show]
      resources :properties, only: [:create, :update, :destroy, :index, :show] do
        get :documents, on: :member
      end
      resources :rooms, only: [:create, :update, :destroy, :index]

      # Milestone 1.5 — Candidatures
      resources :lease_applications, only: [:create, :update, :destroy, :show, :index] do
        member { patch :validate }
      end

      # Milestone Agent (v0.3) — Couche IA
      namespace :agent do
        post :chat                        # Point d'entrée principal
        get  :context                     # Contexte utilisateur
        get  'properties/summary'         # Vue synthétique du parc
        get  'leases/:id/irl'             # Calcul révision IRL
        post 'receipts'                   # Génère une quittance PDF
        get  'documents/:type'            # Lien S3 signé
        post 'notifications/send'         # Déclenche email/SMS
        resources :tickets, only: [:index, :create, :show]
      end
    end
  end

  # Health check
  get '/health', to: proc { [200, {}, ['ok']] }
end
