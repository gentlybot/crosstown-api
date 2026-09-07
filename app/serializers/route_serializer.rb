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
      start_lng: route.start_lng.to_f,
      pay_cents: route.pay_cents,
      courier: CourierSerializer.brief(route.courier),
      offered_at: route.offered_at&.iso8601,
      assigned_at: route.assigned_at&.iso8601,
      started_at: route.started_at&.iso8601,
      completed_at: route.completed_at&.iso8601,
      delivered_count: route.route_stops.count(&:delivered?),
      failed_count: route.route_stops.count(&:failed?)
    }
  end

  def self.detail(route)
    summary(route).merge(
      merchant: MerchantSerializer.brief(route.merchant),
      pay_breakdown: route.pay_breakdown,
      offers: route.route_offers.includes(courier: :user).map { |o| RouteOfferSerializer.for_admin(o) },
      stops: route.route_stops.includes(:order).map { |s| stop(s) }
    )
  end

  # Everything a courier needs at the door, including contact details.
  def self.for_courier(route)
    summary(route).merge(
      merchant: MerchantSerializer.brief(route.merchant),
      pay_breakdown: route.pay_breakdown,
      stops: route.route_stops.includes(:order).map { |s| stop(s, contact: true) }
    )
  end

  def self.stop(stop, contact: false)
    o = stop.order
    base = {
      id: stop.id,
      position: stop.position,
      order_id: o.id,
      batch_id: o.batch_id,
      recipient_name: o.recipient_name,
      address: o.full_address,
      unit: o.unit,
      notes: o.notes,
      quantity: o.quantity,
      leave_at_door: o.leave_at_door,
      lat: stop.lat.to_f,
      lng: stop.lng.to_f,
      leg_km: stop.leg_km.to_f,
      eta: stop.eta.iso8601,
      status: stop.status,
      completed_at: stop.completed_at&.iso8601,
      failure_reason: stop.failure_reason,
      note: stop.note,
      has_photo: stop.photo_data.present?
    }
    base.merge!(recipient_phone: o.recipient_phone, recipient_email: o.recipient_email) if contact
    base
  end
end
