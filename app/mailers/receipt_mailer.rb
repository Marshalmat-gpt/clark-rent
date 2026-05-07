require 'base64'

class ReceiptMailer < ApplicationMailer
  # Envoie une quittance PDF en pièce jointe.
  # `pdf_bytes` est soit une String binaire (deliver_now in-process)
  # soit un blob base64 (envoyé par SendNotificationJob → ActiveJob,
  # JSON-safe). On accepte les deux formes.
  def delivered(lease_id:, period:, pdf_bytes:)
    @lease  = Lease.find(lease_id)
    @tenant = @lease.tenant
    @period = period.is_a?(Date) ? period : Date.parse(period.to_s)

    attachments["quittance-#{@period.strftime('%Y-%m')}.pdf"] = {
      mime_type: 'application/pdf',
      content: decode_pdf(pdf_bytes)
    }
    mail(to: @tenant.email, subject: "Quittance de loyer — #{@period.strftime('%B %Y')}")
  end

  private

  def decode_pdf(payload)
    return payload if payload.start_with?('%PDF')

    Base64.strict_decode64(payload)
  rescue ArgumentError
    payload
  end
end
