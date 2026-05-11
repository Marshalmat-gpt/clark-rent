module Api
  module V1
    module Agent
      class ChatController < BaseController
        MAX_HISTORY = 20

        def create
          message = params.require(:message)
          history = Array(params[:history]).last(MAX_HISTORY)
          reply   = ClarkAgent::Orchestrator.new(user: current_user).chat(message, history: history)
          render json: { reply: reply }
        rescue ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :bad_request
        rescue StandardError => e
          Rails.logger.error "[ChatController] #{e.class}: #{e.message}\n#{e.backtrace.first(3).join("\n")}"
          render json: { error: 'Agent unavailable' }, status: :bad_gateway
        end
      end
    end
  end
end
