class User < ApplicationRecord
  has_secure_password

  has_many :properties, dependent: :destroy

  ROLES = %w[landlord tenant].freeze

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, presence: true
  validates :role, inclusion: { in: ROLES }

  before_save { self.email = email.downcase }
end
