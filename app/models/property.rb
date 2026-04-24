class Property < ApplicationRecord
  belongs_to :user
  has_many :rooms, dependent: :destroy

  validates :name, :address, presence: true
end
