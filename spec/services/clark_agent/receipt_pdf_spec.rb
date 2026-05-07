require 'rails_helper'

RSpec.describe ClarkAgent::ReceiptPdf do
  let(:landlord) { create(:user, role: 'landlord') }
  let(:tenant)   { create(:user, :tenant) }
  let(:property) { create(:property, user: landlord) }
  let(:room)     { create(:room, property: property) }
  let(:lease)    { create(:lease, room: room, tenant: tenant, monthly_rent: 900, monthly_charges: 50) }

  it 'renders a non-empty PDF with %PDF header' do
    io = described_class.new(lease: lease, period: Date.new(2026, 4, 1)).render
    bytes = io.read
    expect(bytes.size).to be > 1000
    expect(bytes[0, 4]).to eq('%PDF')
  end
end
