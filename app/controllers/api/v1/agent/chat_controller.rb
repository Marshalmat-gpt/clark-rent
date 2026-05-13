module Api
  module V1
    module Agent
      class ChatController < BaseController
        def create
          message = params.require(:message)
          session = find_or_build_session
          reply   = ClarkAgent::Orchestrator.new(user: current_user).chat(
            message,
            history: session.history
          )
          session.append_turn(message, reply)
          session.save!
          render json: { reply: reply, session_id: session.id }
        rescue ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :bad_request
        rescue StandardError => e
          Rails.logger.error "[ChatController] #{e.class}: #{e.message}\n#{e.backtrace.first(3).join("\n")}"
          render json: { error: 'Agent unavailable' }, status: :bad_gateway
        end

        private

        # Returns an existing session owned by current_user, or builds a new (unsaved) one.
        # Scoped to current_user to prevent IDOR. New sessions are not persisted until
        # after a successful Orchestrator reply, preventing orphan rows on failure.
        def find_or_build_session
          if params[:session_id].present?
            current_user.chat_sessions.find_by(id: params[:session_id]) ||
              current_user.chat_sessions.build
          else
            current_user.chat_sessions.build
          end
        end
      end
    end
  end
end
