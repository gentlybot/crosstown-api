require "rails_helper"

RSpec.describe Routing::Planner do
  let(:merchant) { create(:merchant, pickup_lat: 43.6472, pickup_lng: -79.4046, cutoff_time: "14:00") }
  let(:date) { Date.new(2026, 9, 9) }
  let(:engine) { Routing::Engines::Savings.new }

  def import(csv_rows, name: "Batch")
    header = "order_id,name,phone,address,postal_code"
    batch = create(:batch, merchant: merchant, name: name, delivery_date: date, raw_csv: ([header] + csv_rows).join("\n") + "\n")
    Batches::CsvImporter.new(batch).call
    batch
  end

  let(:rows) do
    %w[22 60 108 150 210 260 320 380 440 500 540 590 20 88 140].each_with_index.map do |n, i|
      street = i.even? ? "Palmerston Ave" : "Euclid Ave"
      "#{1000 + i},Person #{i},416-555-01#{format('%02d', i)},#{n} #{street},M6J 2J1"
    end
  end

  it "routes every ready order into routes of at most MAX_STOPS, in a sensible order" do
    batch = import(rows)
    routes = described_class.new(merchant, date, engine: engine).call

    expect(routes.size).to be >= 2
    expect(routes.sum(&:stop_count)).to eq(15)
    expect(routes.map(&:stop_count).max).to be <= Routing::Planner::MAX_STOPS
    expect(routes.map(&:route_number)).to eq(routes.map(&:route_number).sort)
    expect(routes.first.route_number).to be >= Route::FIRST_NUMBER

    route = routes.first
    expect(route.route_stops.map(&:position)).to eq((1..route.stop_count).to_a)
    expect(route.route_stops.first.eta).to be > route.start_at
    expect(route.route_stops.map(&:eta)).to eq(route.route_stops.map(&:eta).sort)
    expect(route.distance_km).to be > 0
    expect(route.engine).to eq("savings")

    batch.reload
    expect(batch.status).to eq("routed")
    expect(batch.routed_count).to eq(15)
    expect(batch.orders.where(status: "routed").count).to eq(15)

    plan = RoutePlan.find_by!(merchant: merchant, delivery_date: date)
    expect(plan).to have_attributes(status: "done", routes_count: routes.size, stops_count: 15, engine: "savings")
  end

  it "leaves flagged rows behind and keeps the batch in review" do
    batch = import(rows.first(3) + ["2000,No Address,416-555-0199,,M6J 2J1"])
    described_class.new(merchant, date, engine: engine).call
    batch.reload
    expect(batch.status).to eq("needs_review")
    expect(batch.routed_count).to eq(3)
    expect(batch.orders.find_by(external_id: "2000").status).to eq("problem")
  end

  it "replaces planned routes when run again" do
    import(rows.first(6))
    first = described_class.new(merchant, date, engine: engine).call
    second = described_class.new(merchant, date, engine: engine).call
    expect(Route.where(id: first.map(&:id))).to be_empty
    expect(merchant.routes.where(delivery_date: date).count).to eq(second.size)
    expect(merchant.orders.where(status: "routed").count).to eq(6)
  end

  it "records a failure when the pickup has no coordinates" do
    merchant.update!(pickup_lat: nil, pickup_lng: nil)
    import(rows.first(2))
    expect { described_class.new(merchant, date, engine: engine).call }.to raise_error(Routing::Planner::Failed)
    expect(RoutePlan.find_by!(merchant: merchant, delivery_date: date)).to have_attributes(status: "failed", error: /no coordinates/)
  end

  it "does nothing but finish the plan when there is nothing to route" do
    routes = described_class.new(merchant, date, engine: engine).call
    expect(routes).to be_empty
    expect(RoutePlan.find_by!(merchant: merchant, delivery_date: date).status).to eq("done")
  end
end
