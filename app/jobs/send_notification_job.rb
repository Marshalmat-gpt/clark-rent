# Stub Phase 3 — la dispatch réelle (SendGrid/Twilio) est implémentée
# en Phase 4. Ce job sert de point d'entrée pour `notifications/send`.
class SendNotificationJob < ApplicationJob
  queue_as :default

  def perform(channel:, recipient:, payload: {})
    Rails.logger.info(
      "[SendNotificationJob] channel=#{channel} recipient=#{recipient} " \
      "payload=#{payload.inspect}"
    )
  end
end
