class Property < ApplicationRecord
  belongs_to :user
  has_many :rooms, dependent: :destroy

  validates :name, :address, presence: true
  # Backwards-compat alias for tooling that reads `owner`/`owner_id`.
  alias_attribute :owner_id, :user_id
  def owner = user
end
