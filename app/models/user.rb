class User < ApplicationRecord
  has_secure_password

  has_many :owned_properties,   class_name: 'Property', foreign_key: :owner_id, dependent: :destroy
  has_many :lease_applications, foreign_key: :applicant_id, dependent: :destroy
  has_many :tickets_as_tenant,  class_name: 'Ticket', foreign_key: :tenant_id, dependent: :destroy
  has_many :rent_payments,      foreign_key: :tenant_id, dependent: :destroy

  ROLES = %w[owner tenant].freeze

  validates :email,      presence: true, uniqueness: { case_sensitive: false },
                         format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true
  validates :last_name,  presence: true
  validates :role,       inclusion: { in: ROLES }

  before_save { email.downcase! }

  def full_name  = "#{first_name} #{last_name}"
  def owner?     = role == 'owner'
  def tenant?    = role == 'tenant'

  def properties
    owned_properties
  end

  # Bail actif (locataire) — via candidature approuvée sur bail ouvert
  def active_lease
    lease_applications
      .approved
      .joins(:property_lease)
      .where(property_leases: { status: 'open' })
      .includes(property_lease: :property)
      .first
      &.property_lease
  end
end
