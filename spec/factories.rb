FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    email      { Faker::Internet.unique.email }
    password   { 'password123' }
    role       { 'tenant' }
    phone      { Faker::PhoneNumber.cell_phone }

    trait :owner do
      role { 'owner' }
    end

    trait :tenant do
      role { 'tenant' }
    end
  end

  factory :property do
    association :owner, factory: [:user, :owner]
    address       { Faker::Address.street_address }
    zipcode       { '22000' }
    city          { 'Saint-Brieuc' }
    property_type { 4 }  # T3
    area          { 68.0 }
    furnished     { false }
    energy        { 'C' }
    rent_type     { 'whole' }
  end

  factory :property_lease do
    association :property
    status         { 'open' }
    amount         { 620.0 }
    expense_amount { 80.0 }
    start_date     { 1.year.ago }
    end_date       { 1.year.from_now }
    irl_reference  { 140.59 }
  end

  factory :lease_application do
    association :property_lease
    association :applicant, factory: :user
    status      { 'approved' }
    description { 'Candidature de test' }
  end

  factory :ticket do
    association :property
    association :tenant, factory: :user
    category    { 'plomberie' }
    description { 'Fuite sous le lavabo de la salle de bain' }
    status      { 'open' }
    priority    { 'normal' }

    trait :urgent do
      priority { 'urgent' }
      category { 'chauffage' }
    end
  end

  factory :rent_payment do
    association :lease, factory: :property_lease
    association :tenant, factory: :user
    amount         { 620.0 }
    expense_amount { 80.0 }
    status         { 'paid' }
    due_date       { Date.today.beginning_of_month }
    paid_at        { Date.today }
    payment_method { 'virement' }
  end
end
