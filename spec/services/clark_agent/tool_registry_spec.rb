require 'rails_helper'

RSpec.describe ClarkAgent::ToolRegistry do
  let(:landlord) { create(:user, role: 'landlord') }
  let(:tenant)   { create(:user, :tenant) }
  let(:property) { create(:property, user: landlord) }
  let(:room)     { create(:room, property: property) }

  describe '.tool_specs' do
    it 'exposes the expected tool names' do
      names = described_class.tool_specs.map { |t| t[:name] }
      expect(names).to contain_exactly(
        'get_user_context', 'list_properties', 'calculate_irl_revision',
        'list_tickets', 'create_ticket'
      )
    end
  end

  describe 'get_user_context tool' do
    it 'delegates to ContextBuilder for tenants' do
      result = described_class.find('get_user_context').handler.call(user: tenant)
      expect(result).to include(role: 'tenant')
    end
  end

  describe 'list_properties tool' do
    it 'returns landlord properties with monthly_revenue' do
      create(:lease, room: room, tenant: tenant, monthly_rent: 900, status: 'active')

      out = described_class.find('list_properties').handler.call(user: landlord)
      expect(out).to be_an(Array)
      expect(out.first[:id]).to eq(property.id)
      expect(out.first[:monthly_revenue].to_f).to eq(900.0)
    end

    it 'rejects tenants' do
      out = described_class.find('list_properties').handler.call(user: tenant)
      expect(out).to eq(error: 'Landlord only')
    end
  end

  describe 'calculate_irl_revision tool' do
    it 'returns the revised rent for an own lease' do
      lease = create(:lease, room: room, tenant: tenant, monthly_rent: 850)

      out = described_class.find('calculate_irl_revision').handler.call(
        user: landlord, lease_id: lease.id, base_irl: 136.27, current_irl: 142.06
      )
      expect(out[:revised_rent]).to be_within(0.05).of(886.13)
    end

    it 'returns error when lease not in scope' do
      lease = create(:lease, room: room, tenant: tenant)
      other_landlord = create(:user, role: 'landlord')

      out = described_class.find('calculate_irl_revision').handler.call(
        user: other_landlord, lease_id: lease.id, base_irl: 100, current_irl: 110
      )
      expect(out).to eq(error: 'Lease not found')
    end
  end

  describe 'create_ticket tool' do
    it 'creates a ticket and returns its id' do
      out = described_class.find('create_ticket').handler.call(
        user: tenant, room_id: room.id, title: 'Fuite robinet'
      )
      expect(out[:id]).to be_a(Integer)
      expect(out[:status]).to eq('open')
      expect(Ticket.find(out[:id]).title).to eq('Fuite robinet')
    end

    it 'returns errors when title missing' do
      out = described_class.find('create_ticket').handler.call(
        user: tenant, room_id: room.id, title: ''
      )
      expect(out[:error]).to include("Title")
    end
  end

  describe 'list_tickets tool' do
    it 'filters by status when given' do
      create(:ticket, reporter: tenant, room: room, status: 'open')
      create(:ticket, reporter: tenant, room: room, status: 'closed')

      out = described_class.find('list_tickets').handler.call(user: tenant, status: 'open')
      expect(out.size).to eq(1)
      expect(out.first['status']).to eq('open')
    end
  end
end
