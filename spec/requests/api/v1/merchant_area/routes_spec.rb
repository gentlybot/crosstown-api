require "rails_helper"

RSpec.describe "Merchant routes", type: :request do
  let(:merchant) { create(:merchant, pickup_lat: 43.6472, pickup_lng: -79.4046) }
  let(:user) { create(:user, merchant: merchant) }
  let(:headers) { auth_headers(user) }
  let(:date) { Date.new(2026, 9, 9) }

  before do
    allow(Routing::Engine).to receive(:default).and_return(Routing::Engines::Savings.new)
    Batches::CsvImporter.new(create(:batch, merchant: merchant, delivery_date: date)).call
    Batches::CsvImporter.new(create(:batch, delivery_date: date)).call # someone else's
  end

  it "lets a merchant route their own day and see the result" do
    get "/api/v1/merchant/routes", params: { date: date.iso8601 }, headers: headers
    expect(json).to include("ready_unrouted" => 4, "routed" => 0, "plan" => nil, "routes" => [])

    perform_enqueued_jobs do
      post "/api/v1/merchant/routes/build", params: { date: date.iso8601 }, headers: headers
    end
    expect(response).to have_http_status(:accepted)

    get "/api/v1/merchant/routes", params: { date: date.iso8601 }, headers: headers
    expect(json["plan"]).to include("status" => "done", "stops_count" => 4)
    expect(json["ready_unrouted"]).to eq(0)
    expect(json["routed"]).to eq(4)
    expect(json["routes"].size).to be >= 1
    expect(Route.where(merchant: merchant).sum(:stop_count)).to eq(4)
    expect(Route.where.not(merchant: merchant)).to be_empty, "only the caller's orders are routed"
  end

  it "is closed to staff without a merchant and to couriers" do
    post "/api/v1/merchant/routes/build", params: { date: date.iso8601 }, headers: auth_headers(create(:user, :admin))
    expect(response).to have_http_status(:forbidden)
  end
end
