module Api
  module V1
    module Agent
      class NotificationsController < BaseController
        ALLOWED_CHANNELS = %w[email sms].freeze

        def dispatch_message
          channel   = params.require(:channel)
          recipient = params.require(:recipient)
          payload   = params[:payload].is_a?(ActionController::Parameters) ? params[:payload].permit(:subject, :body, :template_id).to_h : {}

          unless ALLOWED_CHANNELS.include?(channel)
            return render json: { error: "channel must be one of #{ALLOWED_CHANNELS.join(', ')}" },
                          status: :unprocessable_entity
          end

          SendNotificationJob.perform_later(channel: channel, recipient: recipient, payload: payload)
          render json: { status: 'queued', channel: channel, recipient: recipient }, status: :accepted
        rescue ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :bad_request
        end
      end
    end
  end
end
