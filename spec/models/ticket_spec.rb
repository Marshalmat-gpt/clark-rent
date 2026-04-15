require 'rails_helper'

RSpec.describe Ticket, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:description) }
    it { should validate_inclusion_of(:category).in_array(Ticket::CATEGORIES) }
    it { should validate_inclusion_of(:status).in_array(Ticket::STATUSES) }
    it { should validate_inclusion_of(:priority).in_array(Ticket::PRIORITIES) }
  end

  describe 'associations' do
    it { should belong_to(:property) }
    it { should belong_to(:tenant).class_name('User') }
    it { should belong_to(:assigned_to).class_name('User').optional }
  end

  describe 'scopes' do
    let(:owner)    { create(:user, :owner) }
    let(:tenant)   { create(:user, :tenant) }
    let(:property) { create(:property, owner: owner) }

    let!(:open_ticket)     { create(:ticket, property: property, tenant: tenant, status: 'open') }
    let!(:resolved_ticket) { create(:ticket, property: property, tenant: tenant, status: 'resolved') }
    let!(:urgent_ticket)   { create(:ticket, :urgent, property: property, tenant: tenant) }

    it '.open returns only open and assigned tickets' do
      expect(Ticket.open).to include(open_ticket, urgent_ticket)
      expect(Ticket.open).not_to include(resolved_ticket)
    end

    it '.urgent returns only urgent tickets' do
      expect(Ticket.urgent).to include(urgent_ticket)
      expect(Ticket.urgent).not_to include(open_ticket)
    end

    it '.for_owner returns tickets for a specific owner' do
      other_property = create(:property, owner: create(:user, :owner))
      other_ticket   = create(:ticket, property: other_property, tenant: tenant)

      expect(Ticket.for_owner(owner)).to include(open_ticket, urgent_ticket)
      expect(Ticket.for_owner(owner)).not_to include(other_ticket)
    end
  end

  describe '#resolve!' do
    it 'sets status to resolved and records resolved_at' do
      ticket = create(:ticket)
      ticket.resolve!
      expect(ticket.status).to eq('resolved')
      expect(ticket.resolved_at).to be_within(5.seconds).of(Time.current)
    end
  end
end
