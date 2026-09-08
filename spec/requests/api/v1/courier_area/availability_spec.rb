require "rails_helper"

RSpec.describe "Courier availability", type: :request do
  let(:courier) { create(:courier) }
  let(:headers) { auth_headers(courier.user) }
  let(:date) { Date.current + 2.days }

  it "lets a courier set and review future availability" do
    patch "/api/v1/courier/availability", params: { date: date.iso8601, available: true }, headers: headers

    expect(response).to have_http_status(:ok)
    expect(json).to eq("date" => date.iso8601, "available" => true)

    get "/api/v1/courier/availability", params: { from: date.iso8601, to: date.iso8601 }, headers: headers

    expect(response).to have_http_status(:ok)
    expect(json["availability_dates"]).to eq([ date.iso8601 ])
  end

  it "withdraws an open offer when the courier becomes unavailable" do
    merchant = create(:merchant, pickup_lat: 43.6472, pickup_lng: -79.4046)
    batch = create(:batch, merchant: merchant, delivery_date: date)
    Batches::CsvImporter.new(batch).call
    route = Routing::Planner.new(merchant, date, engine: Routing::Engines::Savings.new).call.first
    route.update!(status: "offered")
    offer = RouteOffer.create!(route: route, courier: courier, status: "offered", pay_cents: 1_500, offered_at: Time.current, expires_at: 20.minutes.from_now)
    create(:courier_availability, courier: courier, availability_date: date)

    patch "/api/v1/courier/availability", params: { date: date.iso8601, available: false }, headers: headers

    expect(response).to have_http_status(:ok)
    expect(offer.reload).to be_withdrawn
    expect(route.reload).to be_planned
  end

  it "does not allow a courier to change a past date" do
    patch "/api/v1/courier/availability", params: { date: Date.yesterday.iso8601, available: true }, headers: headers

    expect(response).to have_http_status(422)
    expect(json["error"]).to eq("Availability can only be changed for today or later.")
  end
end
