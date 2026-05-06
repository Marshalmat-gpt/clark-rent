FactoryBot.define do
  factory :lease_application do
    association :tenant, factory: %i[user tenant]
    association :room
    status  { 'pending' }
    message { 'Je suis intéressé par cette chambre.' }
  end
end
