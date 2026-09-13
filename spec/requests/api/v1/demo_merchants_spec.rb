require "rails_helper"

RSpec.describe "Demo merchant sign-ins", type: :request do
  it "signs each MCP contact into its own merchant and preserves the original demo logins" do
    Demo::MerchantSeed.call
    accounts = Demo::MerchantSeed::MERCHANTS.map do |row|
      { email: row.fetch(:contact_email), slug: row.fetch(:slug), role: "merchant_admin" }
    end + Demo::MerchantSeed::LEGACY_USERS

    accounts.each do |account|
      post "/api/v1/session", params: { email: account.fetch(:email), password: "crosstown-demo" }
      expect(response).to have_http_status(:created)
      expect(json.fetch("user")).to include("email" => account.fetch(:email), "role" => account.fetch(:role))
      expect(json.fetch("merchant").fetch("slug")).to eq(account.fetch(:slug))

      get "/api/v1/me", headers: { "Authorization" => "Bearer #{json.fetch('token')}" }
      expect(response).to have_http_status(:ok)
      expect(json.fetch("merchant").fetch("slug")).to eq(account.fetch(:slug))
    end
  end
end
