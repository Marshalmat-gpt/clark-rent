require 'rails_helper'

RSpec.describe TicketMailer, type: :mailer do
  let(:landlord) { create(:user, role: 'landlord', email: 'landlord@example.com') }
  let(:tenant)   { create(:user, :tenant, email: 'tenant@example.com') }
  let(:property) { create(:property, user: landlord) }
  let(:room)     { create(:room, property: property) }
  let(:ticket)   { create(:ticket, reporter: tenant, room: room, title: 'Fuite robinet') }

  describe '#created' do
    it 'notifies the landlord with title' do
      mail = described_class.created(ticket.id)
      expect(mail.to).to eq(['landlord@example.com'])
      expect(mail.subject).to include('Fuite robinet')
    end
  end

  describe '#resolved' do
    it 'notifies the reporter' do
      ticket.resolve!
      mail = described_class.resolved(ticket.id)
      expect(mail.to).to eq(['tenant@example.com'])
      expect(mail.subject).to include('Fuite robinet')
    end
  end
end
