require 'rails_helper'

RSpec.describe RentPayment, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:amount) }
    it { should validate_presence_of(:due_date) }
    it { should validate_numericality_of(:amount).is_greater_than(0) }
    it { should validate_inclusion_of(:status).in_array(RentPayment::STATUSES) }
  end

  describe 'associations' do
    it { should belong_to(:lease).class_name('PropertyLease') }
    it { should belong_to(:tenant).class_name('User') }
  end

  describe '#mark_as_paid!' do
    let(:payment) { create(:rent_payment, status: 'pending', paid_at: nil) }

    it 'sets status to paid and records paid_at' do
      payment.mark_as_paid!(method: 'virement')
      expect(payment.status).to eq('paid')
      expect(payment.paid_at).to eq(Date.today)
      expect(payment.payment_method).to eq('virement')
    end
  end

  describe '#total' do
    it 'returns sum of amount and expense_amount' do
      payment = build(:rent_payment, amount: 620.0, expense_amount: 80.0)
      expect(payment.total).to eq(700.0)
    end
  end

  describe '#days_late' do
    it 'returns 0 when not late' do
      payment = build(:rent_payment, status: 'paid')
      expect(payment.days_late).to eq(0)
    end

    it 'returns number of days overdue when late' do
      payment = build(:rent_payment, status: 'late', due_date: 5.days.ago.to_date)
      expect(payment.days_late).to eq(5)
    end
  end

  describe '.generate_for_lease' do
    let(:owner)    { create(:user, :owner) }
    let(:tenant)   { create(:user, :tenant) }
    let(:property) { create(:property, owner: owner) }
    let(:lease)    { create(:property_lease, property: property, start_date: Date.today) }

    before do
      create(:lease_application, property_lease: lease, applicant: tenant, status: 'approved')
    end

    it 'creates 12 monthly payments by default' do
      payments = RentPayment.generate_for_lease(lease: lease)
      expect(payments.count).to eq(12)
    end

    it 'sets due_date to the 1st of each month' do
      payments = RentPayment.generate_for_lease(lease: lease)
      payments.each { |p| expect(p.due_date.day).to eq(1) }
    end

    it 'is idempotent (no duplicates on re-run)' do
      RentPayment.generate_for_lease(lease: lease)
      RentPayment.generate_for_lease(lease: lease)
      expect(RentPayment.where(lease: lease).count).to eq(12)
    end
  end
end
