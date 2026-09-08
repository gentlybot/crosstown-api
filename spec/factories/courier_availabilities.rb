FactoryBot.define do
  factory :courier_availability do
    courier
    availability_date { Date.current }
  end
end
