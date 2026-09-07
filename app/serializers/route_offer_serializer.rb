module RouteOfferSerializer
  # What a courier sees before accepting: enough to decide, nothing personal.
  def self.for_courier(offer)
    route = offer.route
    {
      id: offer.id,
      status: offer.status,
      pay_cents: offer.pay_cents,
      offered_at: offer.offered_at.iso8601,
      expires_at: offer.expires_at.iso8601,
      route: RouteSerializer.summary(route).merge(
        merchant: MerchantSerializer.brief(route.merchant),
        first_stop_fsa: route.route_stops.first&.order&.fsa,
        pay_breakdown: route.pay_breakdown
      )
    }
  end

  def self.for_admin(offer)
    { id: offer.id, status: offer.status, courier: CourierSerializer.brief(offer.courier), expires_at: offer.expires_at.iso8601, responded_at: offer.responded_at&.iso8601 }
  end
end
