module Routing
  module Distance
    EARTH_KM = 6371.0
    # Straight-line distance understates street distance in a grid city.
    DETOUR_FACTOR = 1.3

    def self.km(a_lat, a_lng, b_lat, b_lng)
      lat1 = to_rad(a_lat)
      lat2 = to_rad(b_lat)
      dlat = lat2 - lat1
      dlng = to_rad(b_lng - a_lng)
      h = Math.sin(dlat / 2)**2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dlng / 2)**2
      2 * EARTH_KM * Math.asin(Math.sqrt(h))
    end

    def self.road_km(a_lat, a_lng, b_lat, b_lng)
      km(a_lat, a_lng, b_lat, b_lng) * DETOUR_FACTOR
    end

    def self.to_rad(deg)
      deg.to_f * Math::PI / 180
    end
    private_class_method :to_rad
  end
end
