require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_inclusion_of(:role).in_array(%w[owner tenant]) }
  end

  describe 'associations' do
    it { should have_many(:owned_properties).class_name('Property') }
    it { should have_many(:lease_applications) }
    it { should have_many(:tickets_as_tenant).class_name('Ticket') }
    it { should have_many(:rent_payments) }
  end

  describe '#full_name' do
    it 'returns concatenated first and last name' do
      user = build(:user, first_name: 'Alice', last_name: 'Martin')
      expect(user.full_name).to eq('Alice Martin')
    end
  end

  describe '#owner? / #tenant?' do
    it 'returns true for owner role' do
      expect(build(:user, :owner).owner?).to be true
      expect(build(:user, :owner).tenant?).to be false
    end

    it 'returns true for tenant role' do
      expect(build(:user, :tenant).tenant?).to be true
      expect(build(:user, :tenant).owner?).to be false
    end
  end

  describe '#active_lease' do
    let(:owner)    { create(:user, :owner) }
    let(:tenant)   { create(:user, :tenant) }
    let(:property) { create(:property, owner: owner) }
    let(:lease)    { create(:property_lease, property: property, status: 'open') }

    context 'with an approved application on an open lease' do
      before { create(:lease_application, property_lease: lease, applicant: tenant, status: 'approved') }

      it 'returns the active lease' do
        expect(tenant.active_lease).to eq(lease)
      end
    end

    context 'with no approved application' do
      it 'returns nil' do
        expect(tenant.active_lease).to be_nil
      end
    end
  end

  describe 'email normalization' do
    it 'downcases email before save' do
      user = create(:user, email: 'ALICE@EXAMPLE.COM')
      expect(user.email).to eq('alice@example.com')
    end
  end
end
