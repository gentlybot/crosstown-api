require "rails_helper"

RSpec.describe "Admin pricing", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:headers) { auth_headers(admin) }
  let!(:bloom) { create(:merchant, business_name: "Bloom & Stem") }
  let!(:loaf) { create(:merchant, business_name: "Corner Loaf") }

  it "edits the global price and merchant-specific future prices in whole cents" do
    patch "/api/v1/admin/pricing", params: {
      default_per_stop_price_cents: 575,
      merchant_prices: [
        { merchant_id: bloom.id, per_stop_price_cents: 650 },
        { merchant_id: loaf.id, per_stop_price_cents: nil }
      ]
    }, headers: headers

    expect(response).to have_http_status(:ok)
    expect(PricingSetting.current.default_per_stop_price_cents).to eq(575)
    expect(bloom.reload.per_stop_price_cents).to eq(650)
    expect(loaf.reload.per_stop_price_cents).to be_nil
    expect(json["pricing"]).to include("default_per_stop_price_cents" => 575)
    expect(json["pricing"]["merchants"]).to include(include("business_name" => "Bloom & Stem", "effective_per_stop_price_cents" => 650))
    expect(json["pricing"]["merchants"]).to include(include("business_name" => "Corner Loaf", "effective_per_stop_price_cents" => 575))
  end

  it "rejects zero and non-integer prices" do
    patch "/api/v1/admin/pricing", params: { default_per_stop_price_cents: 0 }, headers: headers
    expect(response).to have_http_status(422)

    patch "/api/v1/admin/pricing", params: { merchant_prices: [{ merchant_id: bloom.id, per_stop_price_cents: 12.5 }] }, headers: headers
    expect(response).to have_http_status(422)
  end

  it "is closed to merchant users" do
    get "/api/v1/admin/pricing", headers: auth_headers(create(:user))
    expect(response).to have_http_status(:forbidden)
  end
end