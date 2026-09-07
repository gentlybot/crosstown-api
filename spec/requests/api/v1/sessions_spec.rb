require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) { create(:user, email: "maya@example.com", password: "handoff-demo") }

  it "issues a token for a valid email and password" do
    post "/api/v1/session", params: { email: "Maya@Example.com", password: "handoff-demo" }
    expect(response).to have_http_status(:created)
    expect(json["token"]).to be_present
    expect(json["user"]["email"]).to eq("maya@example.com")
    expect(json["merchant"]["id"]).to eq(user.merchant_id)

    get "/api/v1/me", headers: { "Authorization" => "Bearer #{json['token']}" }
    expect(response).to have_http_status(:ok)
    expect(json["user"]["id"]).to eq(user.id)
  end

  it "rejects a wrong password" do
    user
    post "/api/v1/session", params: { email: "maya@example.com", password: "nope" }
    expect(response).to have_http_status(:unauthorized)
    expect(json["error"]).to eq("Email or password is wrong.")
  end

  it "rejects requests without a token" do
    get "/api/v1/me"
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects a forged token" do
    get "/api/v1/me", headers: { "Authorization" => "Bearer not.a.token" }
    expect(response).to have_http_status(:unauthorized)
  end
end
