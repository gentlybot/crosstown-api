module AddressBank
  # Expands the street segments into one row per civic number. Idempotent:
  # the unique index makes re-runs no-ops.
  module Seeder
    SIDE_OFFSET = 0.00011 # about ten metres, so odd and even sides do not overlap
    BATCH = 2_000

    def self.run
      rows = []
      Streets::ALL.each do |segment|
        street_name = Geocoding::Normalizer.street(segment.name)
        city = segment.city || "Toronto"
        min, max = segment.numbers.minmax
        span = [max - min, 1].max.to_f
        dlat = segment.to[0] - segment.from[0]
        dlng = segment.to[1] - segment.from[1]
        length = Math.sqrt(dlat**2 + dlng**2)
        perp_lat = length.zero? ? 0 : -dlng / length
        perp_lng = length.zero? ? 0 : dlat / length

        segment.numbers.each do |n|
          t = (n - min) / span
          side = n.odd? ? 1 : -1
          rows << {
            street_number: n,
            street_name: street_name,
            street_display: segment.name,
            city: city,
            fsa: segment.fsa,
            lat: (segment.from[0] + dlat * t + perp_lat * SIDE_OFFSET * side).round(7),
            lng: (segment.from[1] + dlng * t + perp_lng * SIDE_OFFSET * side).round(7),
            source: "seed",
            created_at: Time.current,
            updated_at: Time.current
          }
        end
      end

      inserted = 0
      rows.each_slice(BATCH) do |slice|
        result = AddressBankEntry.insert_all(slice, unique_by: "index_address_bank_on_street_city_number")
        inserted += result.rows.size
      end
      { candidates: rows.size, inserted: inserted, total: AddressBankEntry.count }
    end
  end
end
