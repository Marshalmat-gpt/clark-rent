class Property < ApplicationRecord
  belongs_to :owner, class_name: 'User'
  has_many :leases,  class_name: 'PropertyLease', dependent: :destroy
  has_many :rooms,   dependent: :destroy
  has_many :tickets, dependent: :destroy
  has_one_attached :cover_image

  PROPERTY_TYPES = {
    studio: 0, chambre: 1,
    t1: 2, t2: 3, t3: 4, t4: 5,
    t5: 6, t6: 7, t7: 8, t8: 9, t9: 10, t10: 11
  }.freeze
  ENERGY_RATINGS = %w[A B C D E F G none].freeze
  RENT_TYPES     = %w[shared whole].freeze

  validates :address, :city, :zipcode, :property_type, presence: true

  scope :by_owner,        ->(user) { where(owner: user) }
  scope :in_city,         ->(city) { where(city: city) }
  scope :with_open_lease, -> { joins(:leases).where(property_leases: { status: 'open' }) }

  def formatted_address   = "#{address}, #{zipcode} #{city}"
  def active_lease        = leases.where(status: 'open').last
  def property_type_label = PROPERTY_TYPES.key(property_type)&.to_s&.upcase || 'Inconnu'
end
