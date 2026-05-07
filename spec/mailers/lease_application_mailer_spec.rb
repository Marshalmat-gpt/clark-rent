require 'rails_helper'

RSpec.describe LeaseApplicationMailer, type: :mailer do
  let(:landlord)    { create(:user, role: 'landlord', email: 'landlord@example.com') }
  let(:tenant)      { create(:user, :tenant, email: 'tenant@example.com') }
  let(:property)    { create(:property, user: landlord) }
  let(:room)        { create(:room, property: property) }
  let(:application) { create(:lease_application, room: room, tenant: tenant) }

  describe '#submitted' do
    it 'is sent to the landlord' do
      mail = described_class.submitted(application.id)
      expect(mail.to).to eq(['landlord@example.com'])
      expect(mail.subject).to eq('Nouvelle candidature Clark Rent')
    end
  end

  describe '#validated' do
    it 'reflects the decision in the subject' do
      application.update!(status: 'approved')
      mail = described_class.validated(application.id)
      expect(mail.to).to eq(['tenant@example.com'])
      expect(mail.subject).to include('acceptée')
    end

    it 'subjects rejected with the right wording' do
      application.update!(status: 'rejected')
      mail = described_class.validated(application.id)
      expect(mail.subject).to include('refusée')
    end
  end
end
