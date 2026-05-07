class TicketSerializer < ActiveModel::Serializer
  attributes :id, :property_id, :tenant_id, :assigned_to_id,
             :category, :description, :status, :priority,
             :resolved_at, :created_at
end
