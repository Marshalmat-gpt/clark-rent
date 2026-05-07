require 'rails_helper'

RSpec.describe ClarkAgent::ContextBuilder do
  let(:landlord) { create(:user, role: 'landlord') }
  let(:tenant)   { create(:user, :tenant) }
  let(:property) { create(:property, user: landlord) }
  let(:room)     { create(:room, property: property) }

  it 'returns landlord-shaped context for landlords' do
    create(:lease, room: room, tenant: tenant, status: 'active')
    create(:ticket, room: room, status: 'open')

    ctx = described_class.new(user: landlord).call
    expect(ctx).to include(role: 'landlord', properties_count: 1, rooms_count: 1)
    expect(ctx[:active_leases_count]).to eq(1)
    expect(ctx[:open_tickets_count]).to eq(1)
  end

  it 'returns tenant-shaped context for tenants' do
    lease = create(:lease, room: room, tenant: tenant, status: 'active')

    ctx = described_class.new(user: tenant).call
    expect(ctx).to include(role: 'tenant')
    expect(ctx[:active_leases]).to include(lease.id)
  end
end
