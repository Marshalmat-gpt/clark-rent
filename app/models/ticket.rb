class Ticket < ApplicationRecord
  STATUSES   = %w[open in_progress resolved closed].freeze
  PRIORITIES = %w[low normal high urgent].freeze

  belongs_to :reporter, class_name: 'User'
  belongs_to :room

  validates :title, presence: true
  validates :status,   inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }

  scope :open_tickets, -> { where(status: %w[open in_progress]) }

  def resolve!
    update!(status: 'resolved', resolved_at: Time.current)
  end
end
