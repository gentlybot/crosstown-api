require "rails_helper"

RSpec.describe "Admin batches", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:headers) { auth_headers(admin) }
  let(:bloom) { create(:merchant, business_name: "Bloom & Stem") }
  let(:loaf) { create(:merchant, business_name: "Corner Loaf") }

  def imported(merchant, name:, delivery_date:)
    batch = create(:batch, merchant: merchant, name: name, delivery_date: delivery_date)
    Batches::CsvImporter.new(batch).call
    batch
  end

  describe "GET /api/v1/admin/batches" do
    it "lists every merchant's batches for the requested day with totals" do
      imported(loaf, name: "Bread", delivery_date: Date.new(2026, 9, 9))
      imported(bloom, name: "Flowers", delivery_date: Date.new(2026, 9, 9))
      imported(bloom, name: "Next week", delivery_date: Date.new(2026, 9, 16))

      get "/api/v1/admin/batches", params: { date: "2026-09-09" }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(json["date"]).to eq("2026-09-09")
      expect(json["batches"].map { |b| [b["merchant"]["business_name"], b["name"]] })
        .to eq([["Bloom & Stem", "Flowers"], ["Corner Loaf", "Bread"]])
      expect(json["totals"]).to include("batches" => 2, "merchants" => 2, "orders" => 14, "problems" => 6, "ready" => 8)
    end

    it "defaults to today and accepts a merchant filter" do
      imported(bloom, name: "Today", delivery_date: Date.current)
      imported(loaf, name: "Also today", delivery_date: Date.current)

      get "/api/v1/admin/batches", params: { merchant_id: loaf.id }, headers: headers
      expect(json["date"]).to eq(Date.current.iso8601)
      expect(json["batches"].map { |b| b["name"] }).to eq(["Also today"])
    end

    it "ignores an unparseable date" do
      get "/api/v1/admin/batches", params: { date: "yesterday" }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(json["date"]).to eq(Date.current.iso8601)
    end

    it "is closed to merchant users" do
      get "/api/v1/admin/batches", headers: auth_headers(create(:user))
      expect(response).to have_http_status(:forbidden)
      expect(json["error"]).to eq("Crosstown staff only.")
    end
  end

  describe "GET /api/v1/admin/batches/:id" do
    it "shows any merchant's batch with its orders and merchant" do
      batch = imported(loaf, name: "Bread", delivery_date: Date.current)
      get "/api/v1/admin/batches/#{batch.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(json["batch"]["merchant"]["business_name"]).to eq("Corner Loaf")
      expect(json["batch"]["orders"].size).to eq(7)
    end
  end

  describe "GET /api/v1/admin/merchants" do
    it "lists merchants alphabetically" do
      loaf
      bloom
      get "/api/v1/admin/merchants", headers: headers
      expect(json["merchants"].map { |m| m["business_name"] }).to eq(["Bloom & Stem", "Corner Loaf"])
    end
  end
end
