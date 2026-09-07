module Offers
  # First accept wins. Everyone else's offer is withdrawn.
  class Accept
    class Unavailable < StandardError; end

    def initialize(offer)
      @offer = offer
    end

    def call
      Route.transaction do
        route = @offer.route.lock!
        raise Unavailable, "This offer has expired." unless @offer.reload.open?
        raise Unavailable, "Another courier took this route." unless route.offered?

        now = Time.current
        @offer.update!(status: "accepted", responded_at: now)
        route.route_offers.where.not(id: @offer.id).offered.update_all(status: "withdrawn", responded_at: now, updated_at: now)
        route.update!(status: "assigned", courier: @offer.courier, assigned_at: now)
        route
      end
    end
  end
end
