require "rails_helper"

RSpec.describe Stops::Complete do
  it "locks the effective cents price when a stop settles and never reprices it" do
    merchant = create(:merchant, per_stop_price_cents: 650)
    batch = create(:batch, merchant: merchant)
    order = merchant.orders.create!(batch: batch, row_number: 1, quantity: 1, status: "routed")
    route = merchant.routes.create!(delivery_date: batch.delivery_date, engine: "savings", start_at: Time.current, start_lat: 43.65, start_lng: -79.38, status: "in_progress")
    stop = route.route_stops.create!(order: order, position: 1, lat: 43.65, lng: -79.38, eta: Time.current)

    described_class.new(stop, status: "delivered").call
    expect(order.reload.settled_price_cents).to eq(650)

    merchant.update!(per_stop_price_cents: 800)
    PricingSetting.current.update!(default_per_stop_price_cents: 900)

    expect(order.reload.settled_price_cents).to eq(650)
    expect(order.status).to eq("delivered")
  end
end