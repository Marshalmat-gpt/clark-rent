class LeaseApplicationMailer < ApplicationMailer
  def submitted(application_id)
    @application = LeaseApplication.find(application_id)
    landlord     = @application.room.property.user
    mail(to: landlord.email, subject: 'Nouvelle candidature Clark Rent')
  end

  def validated(application_id)
    @application = LeaseApplication.find(application_id)
    @tenant      = @application.tenant
    @decision    = @application.status # 'approved' | 'rejected'
    mail(to: @tenant.email, subject: "Candidature #{@decision == 'approved' ? 'acceptée' : 'refusée'}")
  end
end
