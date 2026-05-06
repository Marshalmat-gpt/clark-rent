require 'rails_helper'

RSpec.describe Lease, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:tenant).class_name('User') }
    it { is_expected.to belong_to(:room) }
  end

  describe 'validations' do
    subject { build(:lease) }

    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to validate_presence_of(:monthly_rent) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Lease::STATUSES) }
    it { is_expected.to validate_numericality_of(:monthly_rent).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:monthly_charges).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:deposit).is_greater_than_or_equal_to(0) }

    it 'rejects end_date before start_date' do
      lease = build(:lease, start_date: Date.current, end_date: Date.current - 1.day)
      expect(lease).not_to be_valid
      expect(lease.errors[:end_date]).to include('must be on or after start_date')
    end

    it 'allows nil end_date' do
      expect(build(:lease, end_date: nil)).to be_valid
    end
  end

  describe '#active?' do
    it 'true for active status with no end_date' do
      expect(build(:lease, status: 'active', end_date: nil).active?).to be true
    end

    it 'false when terminated' do
      expect(build(:lease, status: 'terminated').active?).to be false
    end

    it 'false when end_date in the past' do
      expect(build(:lease, status: 'active', end_date: Date.current - 1.day).active?).to be false
    end
  end
end
