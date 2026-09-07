module OrderSerializer
  def self.call(order)
    {
      id: order.id,
      row_number: order.row_number,
      external_id: order.external_id,
      recipient_name: order.recipient_name,
      recipient_phone: order.recipient_phone,
      recipient_email: order.recipient_email,
      address_line: order.address_line,
      unit: order.unit,
      city: order.city,
      postal_code: order.postal_code,
      full_address: order.full_address,
      notes: order.notes,
      quantity: order.quantity,
      leave_at_door: order.leave_at_door,
      status: order.status,
      problems: order.problems,
      lat: order.lat&.to_f,
      lng: order.lng&.to_f,
      geocode_precision: order.geocode_precision,
      route_id: order.route_stop&.route_id,
      route_number: order.route_stop&.route&.route_number,
      stop_position: order.route_stop&.position
    }
  end
end
