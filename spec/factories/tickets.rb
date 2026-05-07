FactoryBot.define do
  factory :ticket do
    association :property
    association :tenant, factory: %i[user tenant]
    category    { 'plomberie' }
    description { 'Le robinet de la cuisine fuit depuis ce matin.' }
    status      { 'open' }
    priority    { 'normal' }
  end
end
