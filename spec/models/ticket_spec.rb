require 'rails_helper'

RSpec.describe Ticket, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:property) }
    it { is_expected.to belong_to(:tenant).class_name('User') }
    it { is_expected.to belong_to(:assigned_to).class_name('User').optional }
  end

  describe 'validations' do
    subject { create(:ticket) }

    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_inclusion_of(:category).in_array(Ticket::CATEGORIES) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Ticket::STATUSES) }
    it { is_expected.to validate_inclusion_of(:priority).in_array(Ticket::PRIORITIES) }
  end

  describe '#resolve!' do
    it 'sets status to resolved + timestamp' do
      ticket = create(:ticket)
      ticket.resolve!
      expect(ticket.reload).to have_attributes(status: 'resolved')
      expect(ticket.resolved_at).not_to be_nil
    end
  end

  describe '.open' do
    it 'includes open and assigned, excludes resolved/closed' do
      open_t   = create(:ticket, status: 'open')
      assigned = create(:ticket, status: 'assigned')
      resolved = create(:ticket, status: 'resolved')

      ids = Ticket.open.pluck(:id)
      expect(ids).to include(open_t.id, assigned.id)
      expect(ids).not_to include(resolved.id)
    end
  end
end
