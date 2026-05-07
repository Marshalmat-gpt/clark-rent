require 'rails_helper'

RSpec.describe RentPayment, type: :model do
  describe 'validations' do
    subject { build(:rent_payment) }

    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
    it { is_expected.to validate_inclusion_of(:status).in_array(RentPayment::STATUSES) }
    it { is_expected.to validate_presence_of(:due_date) }
  end

  describe '#mark_as_paid!' do
    it 'transitions to paid + sets paid_at + method' do
      payment = create(:rent_payment)
      payment.mark_as_paid!(method: 'virement')
      expect(payment.reload).to have_attributes(
        status: 'paid',
        payment_method: 'virement'
      )
      expect(payment.paid_at).to eq(Date.current)
    end
  end

  describe 'before_save lateness check' do
    it 'auto-flags pending payments past due_date as late' do
      payment = build(:rent_payment, status: 'pending', due_date: Date.current - 5.days)
      payment.save!
      expect(payment.status).to eq('late')
      expect(payment.days_late).to eq(5)
    end
  end

  describe '.generate_for_lease' do
    let(:landlord) { create(:user, role: 'landlord') }
    let(:tenant)   { create(:user, :tenant) }
    let(:property) { create(:property, user: landlord) }
    let(:room)     { create(:room, property: property) }
    let(:lease)    do
      create(:lease, room: room, tenant: tenant,
                     monthly_rent: 850, monthly_charges: 50,
                     start_date: Date.new(2026, 1, 15))
    end

    it 'creates N pending payments aligned to the 1st of the month' do
      payments = described_class.generate_for_lease(lease: lease, months: 3)
      expect(payments.size).to eq(3)
      expect(payments.map(&:due_date)).to all(have_attributes(day: 1))
      expect(payments.map(&:amount).uniq).to eq([850.0])
    end

    it 'is idempotent (find_or_create_by)' do
      described_class.generate_for_lease(lease: lease, months: 3)
      expect do
        described_class.generate_for_lease(lease: lease, months: 3)
      end.not_to change(described_class, :count)
    end
  end
end
