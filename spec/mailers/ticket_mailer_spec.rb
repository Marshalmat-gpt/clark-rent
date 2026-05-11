require 'rails_helper'

RSpec.describe TicketMailer, type: :mailer do
  let(:landlord) { create(:user, role: 'landlord', email: 'landlord@example.com') }
  let(:tenant)   { create(:user, :tenant, email: 'tenant@example.com') }
  let(:property) { create(:property, user: landlord) }
  let(:ticket) do
    create(:ticket, tenant: tenant, property: property,
                    category: 'plomberie',
                    description: 'Fuite robinet')
  end

  describe '#created' do
    it 'notifies the landlord' do
      mail = described_class.created(ticket.id)
      expect(mail.to).to eq(['landlord@example.com'])
      expect(mail.subject).to include('Fuite robinet')
    end
  end

  describe '#resolved' do
    it 'notifies the tenant' do
      ticket.resolve!
      mail = described_class.resolved(ticket.id)
      expect(mail.to).to eq(['tenant@example.com'])
      expect(mail.subject).to include('Fuite robinet')
    end
  end

  describe '#escalated' do
    it 'notifies the landlord with ESCALATION subject' do
      mail = described_class.escalated(ticket.id)
      expect(mail.to).to eq(['landlord@example.com'])
      expect(mail.subject).to include('ESCALATION')
      expect(mail.subject).to include('Fuite robinet')
    end
  end
end
