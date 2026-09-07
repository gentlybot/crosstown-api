module Geocoding
  # Looks an address line up in the seeded bank. Exact civic numbers win; a
  # number between two known ones on the same street is interpolated; a number
  # just past the end of a known street is snapped to the end. Anything else is
  # not found.
  module AddressBank
    Result = Struct.new(:lat, :lng, :precision, :fsa, :city, :street_display, keyword_init: true)
    Parsed = Struct.new(:number, :street, keyword_init: true)

    LEADING_UNIT = /\A(?:unit|apt|apartment|suite|ste|#)\s*[\w-]+[\s,-]+/i
    NUMBER_AND_STREET = /\A(\d+)\s*[a-z]?(?:\s*[-–]\s*\d+)?\s+(.+?)\z/i
    SNAP_TOLERANCE = 60

    def self.parse(address_line)
      line = address_line.to_s.strip
      return nil if line.blank?
      line = line.sub(LEADING_UNIT, "")
      line = line.split(",").first.to_s.strip
      m = line.match(NUMBER_AND_STREET)
      return nil unless m
      street = Normalizer.street(m[2])
      return nil if street.blank?
      Parsed.new(number: m[1].to_i, street: street)
    end

    def self.lookup(address_line, city: nil)
      parsed = parse(address_line)
      return nil unless parsed

      scope = AddressBankEntry.where(street_name: parsed.street)
      if city.present?
        in_city = scope.where("lower(city) = ?", city.to_s.strip.downcase)
        scope = in_city if in_city.exists?
      end
      return nil unless scope.exists?

      if (exact = scope.find_by(street_number: parsed.number))
        return build(exact, exact.lat, exact.lng, "exact")
      end

      lower = scope.where("street_number < ?", parsed.number).order(street_number: :desc).first
      upper = scope.where("street_number > ?", parsed.number).order(:street_number).first

      if lower && upper
        t = (parsed.number - lower.street_number).to_f / (upper.street_number - lower.street_number)
        lat = lower.lat + (upper.lat - lower.lat) * t
        lng = lower.lng + (upper.lng - lower.lng) * t
        return build(lower, lat, lng, "interpolated")
      end

      nearest = lower || upper
      return nil unless nearest && (nearest.street_number - parsed.number).abs <= SNAP_TOLERANCE
      build(nearest, nearest.lat, nearest.lng, "approximate")
    end

    def self.build(entry, lat, lng, precision)
      Result.new(lat: lat.to_f.round(7), lng: lng.to_f.round(7), precision: precision, fsa: entry.fsa, city: entry.city, street_display: entry.street_display)
    end
    private_class_method :build
  end
end
