module DeliveryAllowances
  # Allowances reserve service capacity, measured in jobs, not parcels or money.
  # Booking capacity does not create an order, schedule a pickup or build a route.
  module Catalog
    SERVICES = {
      "same_day" => { label: "Same-day deliveries", description: "Outbound deliveries for the same delivery day." },
      "next_day" => { label: "Next-day deliveries", description: "Outbound deliveries for the next delivery day." },
      "return_pickup" => { label: "Return pickups", description: "Collections from recipients back to the merchant." },
      "redelivery" => { label: "Redelivery attempts", description: "Another delivery attempt after an unsuccessful stop." }
    }.transform_values(&:freeze).freeze
  end
end
