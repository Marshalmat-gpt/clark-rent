FactoryBot.define do
  factory :room do
    name         { "Room #{Faker::Number.number(digits: 2)}" }
    surface_area { rand(10.0..80.0).round(2) }
    rent         { rand(300.0..2000.0).round(2) }
    charges      { rand(0.0..200.0).round(2) }
    association :property
  end
end
