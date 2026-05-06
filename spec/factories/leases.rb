FactoryBot.define do
  factory :lease do
    association :tenant, factory: %i[user tenant]
    association :room
    start_date      { Date.current }
    monthly_rent    { 1000.00 }
    monthly_charges { 50.00 }
    deposit         { 1000.00 }
    status          { 'active' }
  end
end
