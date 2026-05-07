require 'rails_helper'

RSpec.describe Ticket, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:reporter).class_name('User') }
    it { is_expected.to belong_to(:room) }
  end

  describe 'validations' do
    subject { build(:ticket) }

    it { is_expected.to validate_presence_of(:title) }
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

  describe '.open_tickets' do
    it 'includes open and in_progress' do
      open_t   = create(:ticket, status: 'open')
      progress = create(:ticket, status: 'in_progress')
      closed   = create(:ticket, status: 'closed')

      ids = Ticket.open_tickets.pluck(:id)
      expect(ids).to include(open_t.id, progress.id)
      expect(ids).not_to include(closed.id)
    end
  end
end
