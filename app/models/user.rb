class User < ApplicationRecord
  has_secure_password

  has_many :properties,         dependent: :destroy
  has_many :leases,             foreign_key: :tenant_id, dependent: :destroy, inverse_of: :tenant
  has_many :lease_applications, foreign_key: :tenant_id, dependent: :destroy, inverse_of: :tenant
  has_many :tenant_tickets,     class_name: 'Ticket', foreign_key: :tenant_id,
                                dependent: :destroy, inverse_of: :tenant
  has_many :assigned_tickets,   class_name: 'Ticket', foreign_key: :assigned_to_id,
                                dependent: :nullify, inverse_of: :assigned_to
  has_many :chat_sessions,      dependent: :destroy

  ROLES = %w[landlord tenant].freeze

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, presence: true
  validates :role, inclusion: { in: ROLES }

  before_save { self.email = email.downcase }
  # Most recent active lease for this user (tenant scope).
  def active_lease
    leases.where(status: 'active').order(start_date: :desc).first
  end
end
