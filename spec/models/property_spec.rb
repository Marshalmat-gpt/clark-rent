require 'rails_helper'

RSpec.describe Property, type: :model do
  subject { build(:property) }

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:address) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:rooms).dependent(:destroy) }
  end
end
