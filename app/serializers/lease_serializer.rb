class LeaseSerializer < ActiveModel::Serializer
  attributes :id, :tenant_id, :room_id, :start_date, :end_date,
             :monthly_rent, :monthly_charges, :deposit, :status,
             :signed_at, :created_at
end
