FactoryBot.define do
  factory :rent_payment do
    association :lease
    tenant         { lease.tenant }
    amount         { lease.monthly_rent }
    expense_amount { lease.monthly_charges }
    status         { 'pending' }
    due_date       { Date.current.next_month.beginning_of_month }
  end
end
