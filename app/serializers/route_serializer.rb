module RouteSerializer
  def self.summary(route)
    {
      id: route.id,
      route_number: route.route_number,
      display_name: route.display_name,
      status: route.status,
      engine: route.engine,
      delivery_date: route.delivery_date.iso8601,
      stop_count: route.stop_count,
      distance_km: route.distance_km.to_f,
      duration_minutes: route.duration_minutes,
      start_at: route.start_at.iso8601,
      start_lat: route.start_lat.to_f,
      start_lng: route.start_lng.to_f
    }
  end

  def self.detail(route)
    summary(route).merge(
      merchant: MerchantSerializer.brief(route.merchant),
      stops: route.route_stops.includes(:order).map { |s| stop(s) }
    )
  end

  def self.stop(stop)
    o = stop.order
    {
      position: stop.position,
      order_id: o.id,
      batch_id: o.batch_id,
      recipient_name: o.recipient_name,
      address: o.full_address,
      quantity: o.quantity,
      leave_at_door: o.leave_at_door,
      lat: stop.lat.to_f,
      lng: stop.lng.to_f,
      leg_km: stop.leg_km.to_f,
      eta: stop.eta.iso8601
    }
  end
end
