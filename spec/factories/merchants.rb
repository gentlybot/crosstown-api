FactoryBot.define do
  factory :merchant do
    sequence(:business_name) { |n| "Shop #{n}" }
    contact_name { "Owner" }
    sequence(:contact_email) { |n| "owner#{n}@example.com" }
    pickup_address_line { "100 King St W" }
    pickup_city { "Toronto" }
    pickup_postal_code { "M5X 1A9" }
    cutoff_time { "14:00" }
  end
end
