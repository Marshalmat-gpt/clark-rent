class Room < ApplicationRecord
  belongs_to :property

  has_many :leases,             dependent: :destroy
  has_many :lease_applications, dependent: :destroy

  validates :name, presence: true
  validates :rent, presence: true, numericality: { greater_than: 0 }
  validates :charges, numericality: { greater_than_or_equal_to: 0 }
  validates :surface_area, numericality: { greater_than: 0 }, allow_nil: true

  def active_lease
    leases.active.where('end_date IS NULL OR end_date >= ?', Date.current).order(start_date: :desc).first
  end
end
