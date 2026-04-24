class RoomSerializer < ActiveModel::Serializer
  attributes :id, :name, :rent, :charges, :surface_area, :property_id
end
