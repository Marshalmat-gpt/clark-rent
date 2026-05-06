class LeaseApplicationSerializer < ActiveModel::Serializer
  attributes :id, :tenant_id, :room_id, :status, :message,
             :validated_at, :validated_by_id, :created_at
end
