require 'rails_helper'

RSpec.describe Room, type: :model do
  subject { build(:room) }

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:rent) }
    it { should validate_numericality_of(:rent).is_greater_than(0) }
    it { should validate_numericality_of(:charges).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:surface_area).is_greater_than(0).allow_nil }
  end

  describe 'associations' do
    it { should belong_to(:property) }
  end
end
