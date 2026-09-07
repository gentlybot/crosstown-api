# Idempotent: safe to rerun on every sandbox rebuild.
PASSWORD = "handoff-demo"

bank = AddressBank::Seeder.run
puts "Address bank: #{bank[:total]} addresses (#{bank[:inserted]} new)."

merchants = {
  "bloom-and-stem" => {
    business_name: "Bloom & Stem", contact_name: "Maya Chen", contact_email: "maya@bloomandstem.example",
    phone: "416-555-0199", pickup_address_line: "641 Queen St W", pickup_city: "Toronto", pickup_postal_code: "M5V 2B7",
    pickup_lat: 43.6472, pickup_lng: -79.4046, cutoff_time: "14:00"
  },
  "corner-loaf" => {
    business_name: "Corner Loaf Bakery", contact_name: "Devin Osei", contact_email: "devin@cornerloaf.example",
    phone: "416-555-0134", pickup_address_line: "1122 Danforth Ave", pickup_city: "Toronto", pickup_postal_code: "M4J 1M3",
    pickup_lat: 43.6836, pickup_lng: -79.3334, cutoff_time: "11:00"
  }
}

merchants.each do |slug, attrs|
  merchant = Merchant.find_or_initialize_by(slug: slug)
  merchant.update!(attrs)
end

users = [
  { email: "maya@bloomandstem.example", name: "Maya Chen", role: "merchant_admin", merchant_slug: "bloom-and-stem" },
  { email: "sam@bloomandstem.example", name: "Sam Whitfield", role: "merchant_staff", merchant_slug: "bloom-and-stem" },
  { email: "devin@cornerloaf.example", name: "Devin Osei", role: "merchant_admin", merchant_slug: "corner-loaf" },
  { email: "ops@handoff.delivery", name: "Priya Raman", role: "admin", merchant_slug: nil }
]

users.each do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  user.name = attrs[:name]
  user.role = attrs[:role]
  user.merchant = attrs[:merchant_slug] && Merchant.find_by!(slug: attrs[:merchant_slug])
  user.password = PASSWORD if user.new_record?
  user.save!
end

puts "Seeded #{Merchant.count} merchants and #{User.count} users. Password for all: #{PASSWORD}"

# Demo batches so the ops view has something to show on first sign-in. Keyed by
# name per merchant; delivery dates are refreshed on every run so they stay
# current. The rows are imported inline rather than through Sidekiq.
seeded_batches = [
  { merchant_slug: "bloom-and-stem", name: "Tuesday flowers", file: "orders-problems.csv", delivery_date: Date.tomorrow, user: "maya@bloomandstem.example" },
  { merchant_slug: "bloom-and-stem", name: "Weekend arrangements", file: "orders-clean.csv", delivery_date: Date.current, user: "sam@bloomandstem.example" },
  { merchant_slug: "corner-loaf", name: "Morning bread run", file: "orders-clean.csv", delivery_date: Date.tomorrow, user: "devin@cornerloaf.example" }
]

seeded_batches.each do |attrs|
  merchant = Merchant.find_by!(slug: attrs[:merchant_slug])
  batch = Batch.find_or_initialize_by(merchant: merchant, name: attrs[:name])
  batch.delivery_date = attrs[:delivery_date]
  if batch.new_record?
    batch.assign_attributes(
      source: "csv",
      original_filename: attrs[:file],
      raw_csv: Rails.root.join("db/seeds", attrs[:file]).read,
      created_by: User.find_by(email: attrs[:user])
    )
    batch.save!
    Batches::CsvImporter.new(batch).call
  else
    batch.save!
    # Batches imported before the address bank existed get placed on the map.
    Batches::CsvImporter.new(batch).call if batch.orders.where(geocode_precision: nil).exists?
  end
end

puts "Seeded #{Batch.count} batches with #{Order.count} orders."
