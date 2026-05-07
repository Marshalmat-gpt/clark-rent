class TicketSerializer < ActiveModel::Serializer
  attributes :id, :room_id, :reporter_id, :title, :description,
             :status, :priority, :resolved_at, :created_at
end
