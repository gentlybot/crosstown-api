module Offers
  # Closes a route's open offers once the window has passed and puts the route
  # back to planned so ops can offer it again.
  class Expire
    def initialize(route)
      @route = route
    end

    def call
      return unless @route.offered?
      open = @route.route_offers.offered.where("expires_at <= ?", Time.current)
      return if open.none?
      Route.transaction do
        open.update_all(status: "expired", updated_at: Time.current)
        @route.update!(status: "planned") if @route.route_offers.offered.none?
      end
    end
  end
end
