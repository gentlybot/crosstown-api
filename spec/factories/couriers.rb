FactoryBot.define do
  factory :courier do
    user { association :user, role: "courier", merchant: nil }
    phone { "416-555-0100" }
    vehicle_type { "car" }
    home_fsa { "M6J" }
  end
end
