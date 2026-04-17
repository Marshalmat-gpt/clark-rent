FactoryBot.define do
  factory :property do
    name    { Faker::Address.community }
    address { Faker::Address.full_address }
    association :user
  end
end
