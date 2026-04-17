class RoomSerializer < ActiveModel::Serializer
  attributes :id, :name, :surface_area, :rent, :charges, :property_id, :created_at
end
