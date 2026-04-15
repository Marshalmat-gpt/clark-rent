class PropertyLease < ApplicationRecord
  belongs_to :property
  has_many :lease_applications, foreign_key: :lease_id, dependent: :destroy
  has_many :rent_payments,      foreign_key: :lease_id, dependent: :destroy
  has_one_attached :document
  has_one_attached :inventory_document

  STATUSES = %w[open closed inprogress].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :amount, presence: true, numericality: { greater_than: 0 }

  scope :open,       -> { where(status: 'open') }
  scope :closed,     -> { where(status: 'closed') }
  scope :inprogress, -> { where(status: 'inprogress') }
  scope :expiring,   ->(days = 60) { where('end_date <= ?', days.days.from_now).where(status: 'open') }

  def tenant          = lease_applications.approved.includes(:applicant).first&.applicant
  def total_monthly   = amount + (expense_amount || 0)
  def days_to_expiry  = end_date ? (end_date - Date.today).to_i : nil
  def expiring_soon?(threshold = 60) = end_date.present? && days_to_expiry <= threshold
end
