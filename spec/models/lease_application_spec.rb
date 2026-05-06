require 'rails_helper'

RSpec.describe LeaseApplication, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:tenant).class_name('User') }
    it { is_expected.to belong_to(:room) }
    it { is_expected.to belong_to(:validated_by).class_name('User').optional }
  end

  describe 'validations' do
    subject { build(:lease_application) }

    it { is_expected.to validate_inclusion_of(:status).in_array(LeaseApplication::STATUSES) }

    it 'rejects duplicate tenant+room' do
      app = create(:lease_application)
      dup = build(:lease_application, tenant: app.tenant, room: app.room)
      expect(dup).not_to be_valid
      expect(dup.errors[:tenant_id]).to include('already applied to this room')
    end
  end

  describe '#approve!' do
    let(:landlord)    { create(:user, role: 'landlord') }
    let(:application) { create(:lease_application) }

    it 'sets status, validated_by and validated_at' do
      application.approve!(by: landlord)
      expect(application.reload).to have_attributes(
        status: 'approved',
        validated_by_id: landlord.id
      )
      expect(application.validated_at).not_to be_nil
    end
  end

  describe '#reject!' do
    let(:landlord)    { create(:user, role: 'landlord') }
    let(:application) { create(:lease_application) }

    it 'sets rejected status' do
      application.reject!(by: landlord)
      expect(application.reload.status).to eq('rejected')
    end
  end
end
