class LeaseApplication < ApplicationRecord
  belongs_to :property_lease, foreign_key: :lease_id
  belongs_to :applicant, class_name: 'User'

  STATUSES = %w[new rejected_by_staff rejected_by_owner inprogress approved].freeze

  validates :status, inclusion: { in: STATUSES }

  scope :approved, -> { where(status: 'approved') }
  scope :pending,  -> { where(status: %w[new inprogress]) }
  scope :rejected, -> { where(status: %w[rejected_by_staff rejected_by_owner]) }

  def approve!         = update!(status: 'approved')
  def reject!(by:)     = update!(status: "rejected_by_#{by}")
  def pending?         = %w[new inprogress].include?(status)
end
