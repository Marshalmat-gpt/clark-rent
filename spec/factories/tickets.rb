FactoryBot.define do
  factory :ticket do
    association :reporter, factory: %i[user tenant]
    association :room
    title       { 'Fuite robinet cuisine' }
    description { 'Le robinet de la cuisine fuit depuis ce matin.' }
    status      { 'open' }
    priority    { 'normal' }
  end
end
