FactoryBot.define do
  factory :user do
    merchant
    sequence(:email) { |n| "user#{n}@example.com" }
    name { "Test User" }
    password { "password123" }
    role { "merchant_admin" }

    trait :admin do
      merchant { nil }
      role { "admin" }
    end
  end
end
