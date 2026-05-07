class Lease < ApplicationRecord
  STATUSES = %w[active ended terminated].freeze

  belongs_to :tenant, class_name: 'User'
  belongs_to :room

  has_many :rent_payments, dependent: :destroy, inverse_of: :lease

  validates :start_date, :monthly_rent, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :monthly_rent, numericality: { greater_than: 0 }
  validates :monthly_charges, :deposit,
            numericality: { greater_than_or_equal_to: 0 }
  validate :end_date_after_start_date

  scope :active, -> { where(status: 'active') }

  def active?
    status == 'active' && (end_date.nil? || end_date >= Date.current)
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, 'must be on or after start_date')
  end
end
