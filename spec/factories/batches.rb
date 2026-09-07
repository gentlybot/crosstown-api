FactoryBot.define do
  factory :batch do
    merchant
    name { "Orders for tomorrow" }
    delivery_date { Date.tomorrow }
    raw_csv { file_fixture("orders.csv").read }
  end
end
