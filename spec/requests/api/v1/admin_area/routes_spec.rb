require "rails_helper"

RSpec.describe "Admin routes", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:headers) { auth_headers(admin) }
  let(:merchant) { create(:merchant, business_name: "Bloom & Stem", pickup_lat: 43.6472, pickup_lng: -79.4046) }
  let(:date) { Date.new(2026, 9, 9) }

  before do
    allow(Routing::Engine).to receive(:default).and_return(Routing::Engines::Savings.new)
    batch = create(:batch, merchant: merchant, delivery_date: date)
    Batches::CsvImporter.new(batch).call
  end

  it "shows what needs routing, builds routes in the background, then lists them" do
    get "/api/v1/admin/routes", params: { date: date.iso8601 }, headers: headers
    entry = json["merchants"].first
    expect(entry["merchant"]["business_name"]).to eq("Bloom & Stem")
    expect(entry["ready_unrouted"]).to eq(4)
    expect(entry["problems"]).to eq(3)
    expect(entry["routes"]).to eq([])
    expect(entry["plan"]).to be_nil
    expect(json["totals"]["unrouted"]).to eq(4)

    perform_enqueued_jobs do
      post "/api/v1/admin/routes/build", params: { merchant_id: merchant.id, date: date.iso8601 }, headers: headers
    end
    expect(response).to have_http_status(:accepted)
    expect(json["plan"]["status"]).to eq("queued")

    get "/api/v1/admin/routes", params: { date: date.iso8601 }, headers: headers
    entry = json["merchants"].first
    expect(entry["plan"]).to include("status" => "done", "engine" => "savings", "stops_count" => 4)
    expect(entry["ready_unrouted"]).to eq(0)
    expect(entry["routed"]).to eq(4)
    expect(entry["routes"].size).to be >= 1
    route = entry["routes"].first
    expect(route["stops"].map { |s| s["position"] }).to eq((1..route["stop_count"]).to_a)
    expect(route["stops"].first).to include("recipient_name", "address", "eta", "lat", "lng")

    get "/api/v1/admin/routes/#{route['id']}", headers: headers
    expect(json["route"]["merchant"]["business_name"]).to eq("Bloom & Stem")

    get "/api/v1/admin/batches/#{Batch.last.id}", headers: headers
    routed = json["batch"]["orders"].select { |o| o["status"] == "routed" }
    expect(routed.size).to eq(4)
    expect(routed.first["route_number"]).to eq(route["route_number"])
    expect(json["batch"]["routes"].map { |r| r["id"] }).to include(route["id"])
  end

  it "is closed to merchant users" do
    post "/api/v1/admin/routes/build", params: { merchant_id: merchant.id, date: date.iso8601 }, headers: auth_headers(create(:user))
    expect(response).to have_http_status(:forbidden)
  end
end
