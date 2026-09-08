require "rails_helper"

RSpec.describe "Courier offers and routes", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:merchant) { create(:merchant, business_name: "Bloom & Stem", pickup_lat: 43.6472, pickup_lng: -79.4046) }
  let(:date) { Date.new(2026, 9, 9) }
  let!(:jordan) { create(:courier) }
  let!(:aisha) { create(:courier) }
  let(:route) do
    batch = create(:batch, merchant: merchant, delivery_date: date)
    Batches::CsvImporter.new(batch).call
    Routing::Planner.new(merchant, date, engine: Routing::Engines::Savings.new).call.first
  end

  before do
    [ jordan, aisha ].each do |courier|
      create(:courier_availability, courier: courier, availability_date: date)
    end
  end

  it "offers a route, lets the first courier accept, runs it, and tells recipients" do
    # Ops offers the route to every active courier available that day.
    perform_enqueued_jobs(except: ExpireOffersJob) do
      post "/api/v1/admin/routes/#{route.id}/offer", headers: auth_headers(admin)
    end
    expect(response).to have_http_status(:ok)
    expect(json["route"]["status"]).to eq("offered")
    expect(json["route"]["offers"].map { |o| o["status"] }).to eq(%w[offered offered])
    expect(json["route"]["pay_cents"]).to eq(Routing::Pay.cents(route))
    expect(ActionMailer::Base.deliveries.map(&:to).flatten).to contain_exactly(jordan.email, aisha.email)

    # Both couriers see it; Jordan accepts first.
    get "/api/v1/courier/offers", headers: auth_headers(aisha.user)
    expect(json["offers"].size).to eq(1)
    expect(json["offers"].first["route"]["merchant"]["business_name"]).to eq("Bloom & Stem")
    expect(json["offers"].first["route"]).not_to have_key("stops"), "offers do not expose recipient details"

    get "/api/v1/courier/offers", headers: auth_headers(jordan.user)
    offer_id = json["offers"].first["id"]
    post "/api/v1/courier/offers/#{offer_id}/accept", headers: auth_headers(jordan.user)
    expect(response).to have_http_status(:ok)
    expect(json["route"]["status"]).to eq("assigned")
    expect(json["route"]["courier"]["name"]).to eq(jordan.name)
    expect(json["route"]["stops"].first).to include("recipient_phone")

    # Aisha's offer was withdrawn.
    get "/api/v1/courier/offers", headers: auth_headers(aisha.user)
    expect(json["offers"]).to be_empty
    aisha_offer = RouteOffer.find_by!(courier: aisha)
    post "/api/v1/courier/offers/#{aisha_offer.id}/accept", headers: auth_headers(aisha.user)
    expect(response).to have_http_status(:conflict)

    # Jordan starts the route and works the stops.
    get "/api/v1/courier/routes", headers: auth_headers(jordan.user)
    expect(json["routes"].map { |r| r["id"] }).to eq([route.id])

    patch "/api/v1/courier/routes/#{route.id}/stops/#{route.route_stops.first.id}", params: { status: "delivered" }, headers: auth_headers(jordan.user)
    expect(response).to have_http_status(422)
    expect(json["error"]).to include("Start the route")

    post "/api/v1/courier/routes/#{route.id}/start", headers: auth_headers(jordan.user)
    expect(json["route"]["status"]).to eq("in_progress")

    stops = route.route_stops.to_a
    photo = "data:image/jpeg;base64,#{Base64.strict_encode64('fake-jpeg-bytes')}"
    perform_enqueued_jobs do
      patch "/api/v1/courier/routes/#{route.id}/stops/#{stops[0].id}", params: { status: "delivered", note: "Left with concierge", photo: photo }, headers: auth_headers(jordan.user)
    end
    expect(response).to have_http_status(:ok)
    first = json["route"]["stops"].find { |s| s["id"] == stops[0].id }
    expect(first).to include("status" => "delivered", "note" => "Left with concierge", "has_photo" => true)
    expect(stops[0].order.reload.status).to eq("delivered")

    patch "/api/v1/courier/routes/#{route.id}/stops/#{stops[1].id}", params: { status: "failed" }, headers: auth_headers(jordan.user)
    expect(response).to have_http_status(422)
    expect(json["error"]).to include("reason")

    perform_enqueued_jobs do
      stops[1..].each do |s|
        patch "/api/v1/courier/routes/#{route.id}/stops/#{s.id}", params: { status: "failed", failure_reason: "no_answer" }, headers: auth_headers(jordan.user)
        expect(response).to have_http_status(:ok)
      end
    end
    expect(json["route"]["status"]).to eq("completed")
    expect(json["route"]["delivered_count"]).to eq(1)
    expect(json["route"]["failed_count"]).to eq(stops.size - 1)

    recipient_mails = ActionMailer::Base.deliveries.select { |m| m.subject.include?("order from Bloom & Stem") }
    expect(recipient_mails.size).to eq(stops.count { |s| s.order.recipient_email.present? })
  end

  it "expires unanswered offers and returns the route to planned" do
    perform_enqueued_jobs(except: ExpireOffersJob) { post "/api/v1/admin/routes/#{route.id}/offer", headers: auth_headers(admin) }
    travel_to(30.minutes.from_now) do
      ExpireOffersJob.perform_now(route.id)
    end
    expect(route.reload.status).to eq("planned")
    expect(route.route_offers.pluck(:status).uniq).to eq(["expired"])
  end

  it "refuses to offer a route that is not planned" do
    route.update!(status: "assigned", courier: jordan)
    post "/api/v1/admin/routes/#{route.id}/offer", headers: auth_headers(admin)
    expect(response).to have_http_status(422)
  end

  it "offers routes only to couriers available on their delivery day" do
    aisha.courier_availabilities.where(availability_date: date).destroy_all

    perform_enqueued_jobs(except: ExpireOffersJob) do
      post "/api/v1/admin/routes/#{route.id}/offer", headers: auth_headers(admin)
    end

    expect(response).to have_http_status(:ok)
    expect(route.route_offers.pluck(:courier_id)).to contain_exactly(jordan.id)
    expect(ActionMailer::Base.deliveries.map(&:to).flatten).to contain_exactly(jordan.email)
  end

  it "keeps couriers out of merchant and admin areas, and merchants out of courier ones" do
    get "/api/v1/courier/offers", headers: auth_headers(create(:user))
    expect(response).to have_http_status(:forbidden)
    get "/api/v1/merchant/batches", headers: auth_headers(jordan.user)
    expect(response).to have_http_status(:forbidden)
    get "/api/v1/admin/batches", headers: auth_headers(jordan.user)
    expect(response).to have_http_status(:forbidden)
  end
end
