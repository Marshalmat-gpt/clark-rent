class Room < ApplicationRecord
  belongs_to :property

  validates :name, presence: true
  validates :rent, presence: true, numericality: { greater_than: 0 }
  validates :charges, numericality: { greater_than_or_equal_to: 0 }
  validates :surface_area, numericality: { greater_than: 0 }, allow_nil: true
end
