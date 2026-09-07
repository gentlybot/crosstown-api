namespace :geocode do
  desc "Geocode orders that have an address but no coordinates yet"
  task backfill: :environment do
    scope = Order.where(lat: nil).where.not(address_line: [nil, ""])
    found = 0
    scope.find_each do |order|
      hit = Geocoding::AddressBank.lookup(order.address_line, city: order.city)
      if hit
        order.update_columns(lat: hit.lat, lng: hit.lng, fsa: hit.fsa, geocode_precision: hit.precision, geocoded_at: Time.current)
        found += 1
      else
        order.update_columns(geocode_precision: "none")
      end
    end
    puts "geocode:backfill checked #{scope.size + found} orders, placed #{found}"
  end
end
