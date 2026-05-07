module Api
  module V1
    module Agent
      class ChatController < BaseController
        def create
          message = params.require(:message)
          history = Array(params[:history])
          reply   = ClarkAgent::Orchestrator.new(user: current_user).chat(message, history: history)
          render json: { reply: reply }
        rescue ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :bad_request
        rescue StandardError => e
          render json: { error: 'Agent unavailable', detail: e.message }, status: :bad_gateway
        end
      end
    end
  end
end
