require "rails_helper"

RSpec.describe "Delivery allowances", type: :request do
  let(:owner) { create(:user) }
  let(:merchant) { owner.merchant }
  let(:staff) { create(:user, merchant: merchant, role: "merchant_staff") }
  let!(:allowance) { merchant.delivery_allowances.create!(service_type: "same_day", monthly_limit: 500) }

  def usage(user, units, period: DeliveryAllowances::Balance.new(user).period_start)
    allowance.delivery_reservations.create!(user: user, units: units, period_start: period, request_key: SecureRandom.uuid)
  end

  def balance(user = staff)
    get "/api/v1/merchant/delivery_allowances", headers: auth_headers(user)
    json["allowances"].find { |row| row["service_type"] == "same_day" }
  end

  def reserve(units = 1, key: SecureRandom.uuid, user: staff, type: "same_day")
    post "/api/v1/merchant/delivery_reservations", headers: auth_headers(user),
      params: { service_type: type, units: units, request_key: key }, as: :json
  end

  it "lists every service, including services the merchant has not enabled" do
    balance
    expect(json["allowances"].map { |row| row["service_type"] }).to eq(%w[same_day next_day return_pickup redelivery])
    expect(json["allowances"].last).to include("enabled" => false, "available_to_you" => 0, "blocked_by" => [ "service_disabled" ])
  end

  it "separates shared usage from staff usage and applies the smaller remaining allowance" do
    usage(owner, 245)
    usage(staff, 75)
    allowance.staff_delivery_limits.create!(user: staff, monthly_limit: 80)

    row = balance
    expect(row["merchant"]).to eq("limit" => 500, "used" => 320, "remaining" => 180)
    expect(row["personal"]).to eq("limit" => 80, "used" => 75, "remaining" => 5)
    expect(row["available_to_you"]).to eq(5)
    expect(balance(owner)["available_to_you"]).to eq(180)
  end

  it "treats no personal limit as uncapped, and zero as blocked" do
    expect(balance["personal"]).to include("limit" => nil, "remaining" => nil)
    allowance.staff_delivery_limits.create!(user: staff, monthly_limit: 0)
    expect(balance).to include("available_to_you" => 0, "blocked_by" => [ "personal_limit" ])
    reserve
    expect(response).to have_http_status(422)
    expect(json["error"]).to include("personal limit")
  end

  it "keeps a service disabled even when a staff member has a positive limit" do
    allowance.update!(enabled: false)
    allowance.staff_delivery_limits.create!(user: staff, monthly_limit: 50)
    expect(balance).to include("available_to_you" => 0, "blocked_by" => [ "service_disabled" ])
    reserve
    expect(response).to have_http_status(422)
  end

  it "cannot borrow from another service's allowance" do
    allowance.update!(monthly_limit: 0)
    merchant.delivery_allowances.create!(service_type: "next_day", monthly_limit: 100)
    expect(balance).to include("blocked_by" => [ "merchant_limit" ])
    reserve
    expect(response).to have_http_status(422)
    expect(json["error"]).to include("merchant")
  end

  it "reserves against both levels and rejects the next booking when the personal cap is reached" do
    allowance.staff_delivery_limits.create!(user: staff, monthly_limit: 5)
    reserve(5)
    expect(response).to have_http_status(:ok)
    expect(balance["merchant"]["remaining"]).to eq(495)
    expect(balance["personal"]["remaining"]).to eq(0)
    reserve
    expect(response).to have_http_status(422)
    expect(allowance.delivery_reservations.sum(:units)).to eq(5)
  end

  it "enforces the shared cap across different staff" do
    allowance.update!(monthly_limit: 5)
    reserve(4, user: owner)
    reserve(2)
    expect(response).to have_http_status(422)
    reserve(1)
    expect(response).to have_http_status(:ok)
    expect(balance["available_to_you"]).to eq(0)
  end

  it "does not charge twice for a retry and rejects a conflicting request key" do
    reserve(5, key: "order-123")
    id = json["reservation"]["id"]
    reserve(5, key: "order-123")
    expect(json["reservation"]["id"]).to eq(id)
    expect(allowance.delivery_reservations.count).to eq(1)
    reserve(6, key: "order-123")
    expect(response).to have_http_status(:conflict)
  end

  it "cancels once, releases both limits, and never revives a cancelled retry" do
    allowance.staff_delivery_limits.create!(user: staff, monthly_limit: 10)
    reserve(5, key: "cancel-me")
    id = json["reservation"]["id"]
    2.times do
      delete "/api/v1/merchant/delivery_reservations/#{id}", headers: auth_headers(staff)
      expect(response).to have_http_status(:no_content)
    end
    expect(balance["personal"]["remaining"]).to eq(10)
    expect(balance["merchant"]["remaining"]).to eq(500)
    reserve(5, key: "cancel-me")
    expect(json["reservation"]["cancelled_at"]).to be_present
    expect(allowance.delivery_reservations.active.count).to eq(0)
  end

  it "uses the merchant's local month and resets both usage totals at its boundary" do
    merchant.update!(timezone: "America/Toronto")
    allowance.staff_delivery_limits.create!(user: staff, monthly_limit: 10)
    travel_to(Time.utc(2026, 10, 1, 3, 59)) do
      reserve(5, key: "month-end")
      expect(json["reservation"]["period_start"]).to eq("2026-09-01")
      expect(balance["personal"]["used"]).to eq(5)
    end
    travel_to(Time.utc(2026, 10, 1, 4, 0)) do
      expect(balance["merchant"]["used"]).to eq(0)
      expect(balance["personal"]["used"]).to eq(0)
      expect(json["resets_on"]).to eq("2026-11-01")
      reserve(5, key: "month-end")
      expect(json["reservation"]["period_start"]).to eq("2026-09-01")
      expect(balance["merchant"]["used"]).to eq(0)
    end
  end

  it "clamps remaining values if limits are reduced below prior use" do
    usage(staff, 8)
    allowance.update!(monthly_limit: 5)
    allowance.staff_delivery_limits.create!(user: staff, monthly_limit: 3)
    expect(balance).to include("available_to_you" => 0, "blocked_by" => %w[merchant_limit personal_limit])
  end

  it "does not reveal another merchant's usage or allow cancelling someone else's reservation" do
    record = usage(owner, 10)
    other = create(:user)
    expect(balance(other)["merchant"]["used"]).to eq(0)
    [ staff, other ].each do |user|
      delete "/api/v1/merchant/delivery_reservations/#{record.id}", headers: auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end
    expect(record.reload.cancelled_at).to be_nil
  end

  it "requires a merchant session" do
    get "/api/v1/merchant/delivery_allowances"
    expect(response).to have_http_status(:unauthorized)
    [ create(:user, :admin), create(:courier).user ].each do |user|
      get "/api/v1/merchant/delivery_allowances", headers: auth_headers(user)
      expect(response).to have_http_status(:forbidden)
      reserve(user: user)
      expect(response).to have_http_status(:forbidden)
    end
  end

  it "rejects invalid units, unknown services and missing request keys without writing" do
    [ 0, -1, 1.5, "2", nil ].each do |units|
      reserve(units)
      expect(response).to have_http_status(422)
    end
    reserve(type: "teleport")
    expect(response).to have_http_status(422)
    reserve(key: "")
    expect(response).to have_http_status(422)
    expect(allowance.delivery_reservations.count).to eq(0)
  end

  it "rejects limits and reservations belonging to another merchant" do
    other = create(:user)
    expect { allowance.staff_delivery_limits.create!(user: other, monthly_limit: 5) }.to raise_error(ActiveRecord::RecordInvalid)
    expect { usage(other, 5) }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
