class PropertySerializer < ActiveModel::Serializer
  attributes :id, :name, :address, :user_id, :created_at
end
