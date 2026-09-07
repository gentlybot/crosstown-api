module Routing
  # A place the solver must visit. `id` is echoed back in the solution.
  Point = Struct.new(:id, :lat, :lng, :service_seconds, keyword_init: true) do
    def initialize(id:, lat:, lng:, service_seconds: 240)
      super(id: id, lat: lat.to_f, lng: lng.to_f, service_seconds: service_seconds)
    end
  end

  # Ordered stop ids per route, plus anything the solver could not place.
  Solution = Struct.new(:routes, :unassigned, :engine, keyword_init: true)
end
