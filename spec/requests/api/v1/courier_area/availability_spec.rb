require "rails_helper"

RSpec.describe "Courier availability", type: :request do
  let(:courier) { create(:courier) }
  let(:headers) { auth_headers(courier.user) }
  let(:date) { Date.current + 2.days }

  def build_offered_route
    merchant = create(:merchant, pickup_lat: 43.6472, pickup_lng: -79.4046)
    batch = create(:batch, merchant: merchant, delivery_date: date)
    Batches::CsvImporter.new(batch).call
    Routing::Planner.new(merchant, date, engine: Routing::Engines::Savings.new).call.first.tap { |route| route.update!(status: "offered") }
  end

  it "lets a courier set and review future availability" do
    patch "/api/v1/courier/availability", params: { date: date.iso8601, available: true }, as: :json, headers: headers

    expect(response).to have_http_status(:ok)
    expect(json).to eq("date" => date.iso8601, "available" => true)

    get "/api/v1/courier/availability", params: { from: date.iso8601, to: date.iso8601 }, headers: headers

    expect(response).to have_http_status(:ok)
    expect(json["availability_dates"]).to eq([ date.iso8601 ])
  end

  it "requires a boolean availability value" do
    create(:courier_availability, courier: courier, availability_date: date)

    [ nil, "false", "maybe" ].each do |available|
      patch "/api/v1/courier/availability", params: { date: date.iso8601, available: available }, as: :json, headers: headers

      expect(response).to have_http_status(422)
      expect(courier.courier_availabilities.on(date)).to exist
    end

    patch "/api/v1/courier/availability", params: { date: date.iso8601, available: false }, as: :json, headers: headers

    expect(response).to have_http_status(:ok)
    expect(json).to eq("date" => date.iso8601, "available" => false)
    expect(courier.courier_availabilities.on(date)).not_to exist
  end

  it "withdraws an open offer when the courier becomes unavailable" do
    route = build_offered_route
    offer = RouteOffer.create!(route: route, courier: courier, status: "offered", pay_cents: 1_500, offered_at: Time.current, expires_at: 20.minutes.from_now)
    create(:courier_availability, courier: courier, availability_date: date)

    patch "/api/v1/courier/availability", params: { date: date.iso8601, available: false }, as: :json, headers: headers

    expect(response).to have_http_status(:ok)
    expect(offer.reload).to be_withdrawn
    expect(route.reload).to be_planned
  end

  it "does not withdraw an offer accepted while availability removal waits on its route" do
    route = build_offered_route
    offer = RouteOffer.create!(route: route, courier: courier, status: "offered", pay_cents: 1_500, offered_at: Time.current, expires_at: 20.minutes.from_now)
    create(:courier_availability, courier: courier, availability_date: date)
    accepting = false

    allow(Route).to receive(:lock).and_wrap_original do |original, *args, &block|
      unless accepting
        accepting = true
        begin
          Offers::Accept.new(offer).call
        ensure
          accepting = false
        end
      end
      original.call(*args, &block)
    end

    patch "/api/v1/courier/availability", params: { date: date.iso8601, available: false }, as: :json, headers: headers

    expect(response).to have_http_status(:ok)
    expect(offer.reload).to be_accepted
    expect(route.reload).to be_assigned
    expect(route.courier).to eq(courier)
  end

  it "leaves elapsed offers for the expiry job" do
    route = build_offered_route
    offer = RouteOffer.create!(route: route, courier: courier, status: "offered", pay_cents: 1_500, offered_at: 30.minutes.ago, expires_at: 1.minute.ago)
    create(:courier_availability, courier: courier, availability_date: date)

    patch "/api/v1/courier/availability", params: { date: date.iso8601, available: false }, as: :json, headers: headers

    expect(response).to have_http_status(:ok)
    expect(offer.reload).to be_offered
    Offers::Expire.new(route).call
    expect(offer.reload).to be_expired
    expect(route.reload).to be_planned
  end

  it "does not allow a courier to change a past date" do
    patch "/api/v1/courier/availability", params: { date: Date.yesterday.iso8601, available: true }, as: :json, headers: headers

    expect(response).to have_http_status(422)
    expect(json["error"]).to eq("Availability can only be changed for today or later.")
  end
end
