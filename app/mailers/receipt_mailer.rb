class ReceiptMailer < ApplicationMailer
  # Envoie une quittance PDF en pièce jointe.
  # `pdf_io` doit être un IO (StringIO produit par ClarkAgent::ReceiptPdf).
  def delivered(lease_id:, period:, pdf_io:)
    @lease  = Lease.find(lease_id)
    @tenant = @lease.tenant
    @period = period.is_a?(Date) ? period : Date.parse(period.to_s)
    pdf_io.rewind if pdf_io.respond_to?(:rewind)
    attachments["quittance-#{@period.strftime('%Y-%m')}.pdf"] = {
      mime_type: 'application/pdf',
      content: pdf_io.read
    }
    mail(to: @tenant.email, subject: "Quittance de loyer — #{@period.strftime('%B %Y')}")
  end
end
