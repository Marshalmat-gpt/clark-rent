class User < ApplicationRecord
  has_secure_password

  has_many :properties,         dependent: :destroy
  has_many :leases,             foreign_key: :tenant_id, dependent: :destroy, inverse_of: :tenant
  has_many :lease_applications, foreign_key: :tenant_id, dependent: :destroy, inverse_of: :tenant

  ROLES = %w[landlord tenant].freeze

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, presence: true
  validates :role, inclusion: { in: ROLES }

  before_save { self.email = email.downcase }
end
