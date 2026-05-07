# Service d'abstraction Twilio SMS — utilisé par SendNotificationJob.
#
# Configuration via env :
#   TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_FROM
#
# Usage :
#   TwilioSms.send(to: '+33612345678', body: 'Votre quittance est disponible.')
require 'twilio-ruby'

class TwilioSms
  class ConfigurationError < StandardError; end

  class << self
    def send(to:, body:)
      raise ConfigurationError, 'TWILIO_FROM not set' if from_number.blank?

      client.messages.create(from: from_number, to: to, body: body)
    end

    def configured?
      ENV['TWILIO_ACCOUNT_SID'].present? &&
        ENV['TWILIO_AUTH_TOKEN'].present? &&
        from_number.present?
    end

    private

    def client
      @client ||= Twilio::REST::Client.new(
        ENV.fetch('TWILIO_ACCOUNT_SID'),
        ENV.fetch('TWILIO_AUTH_TOKEN')
      )
    end

    def from_number
      ENV['TWILIO_FROM']
    end
  end
end
