module Routing
  # What a route pays the courier, in cents. Matches the public pay sheet:
  # a base, a per-stop amount, a per-kilometre amount.
  module Pay
    BASE_CENTS = 1800
    PER_STOP_CENTS = 225
    PER_KM_CENTS = 45

    def self.cents(route)
      BASE_CENTS + PER_STOP_CENTS * route.stop_count + (PER_KM_CENTS * route.distance_km.to_f).round
    end

    def self.breakdown(route)
      [
        { label: "Base for the route", cents: BASE_CENTS },
        { label: "#{route.stop_count} stops at $#{'%.2f' % (PER_STOP_CENTS / 100.0)}", cents: PER_STOP_CENTS * route.stop_count },
        { label: "#{route.distance_km.to_f} km at $#{'%.2f' % (PER_KM_CENTS / 100.0)}", cents: (PER_KM_CENTS * route.distance_km.to_f).round }
      ]
    end
  end
end
