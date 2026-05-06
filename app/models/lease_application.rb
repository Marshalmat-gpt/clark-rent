class LeaseApplication < ApplicationRecord
  STATUSES = %w[pending approved rejected].freeze

  belongs_to :tenant, class_name: 'User'
  belongs_to :room
  belongs_to :validated_by, class_name: 'User', optional: true

  validates :status, inclusion: { in: STATUSES }
  validates :tenant_id, uniqueness: { scope: :room_id,
                                      message: 'already applied to this room' }

  scope :pending, -> { where(status: 'pending') }

  def approve!(by:)
    update!(status: 'approved', validated_by: by, validated_at: Time.current)
  end

  def reject!(by:)
    update!(status: 'rejected', validated_by: by, validated_at: Time.current)
  end
end
