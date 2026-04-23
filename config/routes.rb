Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :sessions, only: [:create, :destroy]
      resources :users,      only: [:create, :update, :destroy, :index, :show]
      resources :properties, only: [:create, :update, :destroy, :index, :show] do
        get :documents, on: :member
      end
      resources :rooms, only: [:create, :update, :destroy, :index]
      resources :lease_applications, only: [:create, :update, :destroy, :show, :index] do
        member { patch :validate }
      end
      namespace :agent do
        post :chat
        get  :context
        get  'properties/summary'
        get  'leases/:id/irl'
        post 'receipts'
        get  'documents/:type'
        post 'notifications/send'
        resources :tickets, only: [:index, :create, :show]
      end
    end
  end

  get '/health', to: ->(env) { [200, {}, ['ok']] }
end
