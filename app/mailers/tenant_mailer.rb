class TenantMailer < ApplicationMailer
  # Email de quittance mensuelle au locataire
  def rent_receipt(lease:, month:, url:)
    @lease    = lease
    @tenant   = lease.tenant
    @property = lease.property
    @month    = month
    @url      = url
    @amount   = lease.amount + (lease.expense_amount || 0)

    mail(
      to:      @tenant.email,
      subject: "Clark — Votre quittance de loyer #{month.strftime('%B %Y')}"
    )
  end

  # Email de bienvenue à la signature du bail
  def welcome(lease:)
    @lease    = lease
    @tenant   = lease.tenant
    @property = lease.property

    mail(
      to:      @tenant.email,
      subject: "Clark — Bienvenue dans votre logement !"
    )
  end

  # Email de rappel de paiement (J-5 avant échéance)
  def payment_reminder(lease:)
    @lease    = lease
    @tenant   = lease.tenant
    @amount   = lease.amount + (lease.expense_amount || 0)

    mail(
      to:      @tenant.email,
      subject: "Clark — Rappel : votre loyer est dû dans 5 jours"
    )
  end
end
