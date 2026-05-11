require 'rails_helper'

RSpec.describe GenerateMonthlyRentPaymentsJob, type: :job do
  let(:landlord) { create(:user, role: 'landlord') }
  let(:tenant)   { create(:user, :tenant) }
  let(:property) { create(:property, user: landlord) }
  let(:room)     { create(:room, property: property) }

  it 'generates MONTHS_AHEAD payments for each active lease' do
    active_a = create(:lease, room: room, tenant: tenant, status: 'active')
    active_b = create(:lease,
                      room: create(:room, property: property),
                      tenant: create(:user, :tenant),
                      status: 'active')

    expect do
      described_class.new.perform
    end.to change(RentPayment, :count).by(described_class::MONTHS_AHEAD * 2)

    expect(active_a.rent_payments.count).to eq(described_class::MONTHS_AHEAD)
    expect(active_b.rent_payments.count).to eq(described_class::MONTHS_AHEAD)
  end

  it 'skips terminated leases' do
    create(:lease, room: room, tenant: tenant, status: 'terminated')
    expect do
      described_class.new.perform
    end.not_to change(RentPayment, :count)
  end

  it 'is idempotent (no duplicates on rerun)' do
    create(:lease, room: room, tenant: tenant, status: 'active')
    described_class.new.perform
    expect { described_class.new.perform }.not_to change(RentPayment, :count)
  end
end
