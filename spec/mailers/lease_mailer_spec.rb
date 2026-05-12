require 'rails_helper'

RSpec.describe LeaseMailer, type: :mailer do
  let(:landlord) { create(:user, role: 'landlord') }
  let(:tenant)   { create(:user, :tenant, email: 'tenant@example.com') }
  let(:property) { create(:property, user: landlord, address: '1 rue de Rivoli') }
  let(:room)     { create(:room, property: property, name: 'Chambre 1') }
  let(:lease)    { create(:lease, room: room, tenant: tenant, monthly_rent: 900, monthly_charges: 50) }

  describe '#signed' do
    let(:mail) { described_class.signed(lease.id) }

    it 'targets the tenant' do
      expect(mail.to).to eq(['tenant@example.com'])
    end

    it 'has the localised subject' do
      expect(mail.subject).to eq('Votre bail Clark Rent est signé')
    end

    it 'mentions the room and total rent' do
      body = mail.body.encoded
      expect(body).to include('Chambre 1')
      expect(body).to include('1 rue de Rivoli')
      expect(body).to include('950')
    end
  end

  describe '#terminated' do
    it 'targets the tenant with end notice' do
      mail = described_class.terminated(lease.id)
      expect(mail.to).to eq(['tenant@example.com'])
      expect(mail.subject).to eq('Fin de votre bail Clark Rent')
    end
  end
  describe '#irl_revision_due' do
    it 'notifies the landlord with anniversary subject' do
      mail = described_class.irl_revision_due(lease.id)
      expect(mail.to).to eq([landlord.email])
      expect(mail.subject).to include('Révision annuelle IRL')
    end
  end
end
