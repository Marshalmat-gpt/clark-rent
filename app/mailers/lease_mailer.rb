class LeaseMailer < ApplicationMailer
  def signed(lease_id)
    @lease   = Lease.find(lease_id)
    @tenant  = @lease.tenant
    @room    = @lease.room
    mail(to: @tenant.email, subject: 'Votre bail Clark Rent est signé')
  end

  def terminated(lease_id)
    @lease  = Lease.find(lease_id)
    @tenant = @lease.tenant
    mail(to: @tenant.email, subject: 'Fin de votre bail Clark Rent')
  end

  # Annual anniversary reminder: prompts the landlord to review IRL.
  def irl_revision_due(lease_id)
    @lease    = Lease.find(lease_id)
    @landlord = @lease.room.property.user
    @tenant   = @lease.tenant
    mail(to: @landlord.email, subject: 'Révision annuelle IRL à étudier')
  end
end
