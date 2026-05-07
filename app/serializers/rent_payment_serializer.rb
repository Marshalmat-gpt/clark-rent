class RentPaymentSerializer < ActiveModel::Serializer
  attributes :id, :lease_id, :tenant_id, :amount, :expense_amount,
             :status, :due_date, :paid_at, :payment_method,
             :created_at
end
