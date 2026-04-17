require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_inclusion_of(:role).in_array(%w[landlord tenant]) }
    it { should have_secure_password }
  end

  describe 'associations' do
    it { should have_many(:properties).dependent(:destroy) }
  end

  describe 'email normalization' do
    it 'downcases email before saving' do
      user = create(:user, email: 'TEST@EXAMPLE.COM')
      expect(user.reload.email).to eq('test@example.com')
    end
  end
end
