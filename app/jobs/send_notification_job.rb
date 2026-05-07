# Dispatcher générique appelé par /api/v1/agent/notifications/send.
#
# Pour `email` :
#   - mailer  : 'LeaseMailer' (string)
#   - action  : 'signed' (string)
#   - args    : [42]  (positional) ou { lease_id: 42 } (kwargs)
# Si mailer/action manquent, fallback ActionMailer brut (subject + body).
#
# Pour `sms` :
#   - body    : 'Votre quittance est disponible.'
class SendNotificationJob < ApplicationJob
  queue_as :default

  def perform(channel:, recipient:, payload: {})
    case channel.to_s
    when 'email' then dispatch_email(recipient, payload)
    when 'sms'   then dispatch_sms(recipient, payload)
    else
      Rails.logger.warn("[SendNotificationJob] unknown channel=#{channel}")
    end
  end

  private

  def dispatch_email(recipient, payload)
    mailer_class = fetch(payload, :mailer)
    action       = fetch(payload, :action)

    if mailer_class.present? && action.present?
      args, kwargs = mailer_args(payload)
      mailer_class.constantize.public_send(action, *args, **kwargs).deliver_now
    else
      deliver_raw_email(recipient, payload)
    end
  end

  def mailer_args(payload)
    raw = fetch(payload, :args) || []
    if raw.is_a?(Hash)
      [[], raw.transform_keys(&:to_sym)]
    else
      [Array(raw), {}]
    end
  end

  def deliver_raw_email(recipient, payload)
    ActionMailer::Base.mail(
      to: recipient,
      subject: fetch(payload, :subject) || '(no subject)',
      body: fetch(payload, :body) || ''
    ).deliver_now
  end

  def dispatch_sms(recipient, payload)
    body = fetch(payload, :body)
    return Rails.logger.warn('[SendNotificationJob] sms without body') if body.blank?

    if TwilioSms.configured?
      TwilioSms.send(to: recipient, body: body)
    else
      Rails.logger.info("[SendNotificationJob] SMS skipped (Twilio not configured) to=#{recipient}")
    end
  end

  def fetch(payload, key)
    payload[key.to_s] || payload[key.to_sym]
  end
end
