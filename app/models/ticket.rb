class Ticket < ApplicationRecord
  belongs_to :property
  belongs_to :tenant,      class_name: 'User'
  belongs_to :assigned_to, class_name: 'User', optional: true

  CATEGORIES = %w[plomberie electricite chauffage serrurerie autre].freeze
  STATUSES   = %w[open assigned resolved closed].freeze
  PRIORITIES = %w[normal urgent].freeze

  validates :category,    inclusion: { in: CATEGORIES }
  validates :status,      inclusion: { in: STATUSES }
  validates :priority,    inclusion: { in: PRIORITIES }
  validates :description, presence: true

  scope :open,      -> { where(status: %w[open assigned]) }
  scope :urgent,    -> { where(priority: 'urgent') }
  scope :for_owner, ->(user) { joins(:property).where(properties: { owner_id: user.id }) }

  def resolve!
    update!(status: 'resolved', resolved_at: Time.current)
  end
end
