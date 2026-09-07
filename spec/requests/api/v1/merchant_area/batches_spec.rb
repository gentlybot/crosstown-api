require "rails_helper"

RSpec.describe "Merchant batches", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "POST /api/v1/merchant/batches" do
    it "accepts a CSV, imports it in the background, and reports the results" do
      file = fixture_file_upload("orders.csv", "text/csv")

      perform_enqueued_jobs do
        post "/api/v1/merchant/batches", params: { file: file, delivery_date: "2026-09-09", name: "Tuesday flowers" }, headers: headers
      end

      expect(response).to have_http_status(:accepted)
      batch_id = json["batch"]["id"]
      expect(json["batch"]["status"]).to eq("importing")

      get "/api/v1/merchant/batches/#{batch_id}", headers: headers
      expect(response).to have_http_status(:ok)
      batch = json["batch"]
      expect(batch["name"]).to eq("Tuesday flowers")
      expect(batch["delivery_date"]).to eq("2026-09-09")
      expect(batch["status"]).to eq("needs_review")
      expect(batch["row_count"]).to eq(7)
      expect(batch["problem_count"]).to eq(3)
      expect(batch["orders"].size).to eq(7)
      expect(batch["orders"].find { |o| o["external_id"] == "1005" }["problems"]).to eq(["Postal code does not look valid"])

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([user.email])
      expect(mail.subject).to include("3 of 7 orders need attention")
    end

    it "defaults the delivery date to tomorrow and names the batch" do
      post "/api/v1/merchant/batches", params: { file: fixture_file_upload("orders.csv", "text/csv") }, headers: headers
      expect(response).to have_http_status(:accepted)
      expect(json["batch"]["delivery_date"]).to eq(Date.tomorrow.iso8601)
      expect(json["batch"]["name"]).to start_with("Orders for ")
    end

    it "marks the batch failed when the file is not usable" do
      bad = Rack::Test::UploadedFile.new(StringIO.new("name,phone\nPat,416\n"), "text/csv", original_filename: "bad.csv")
      perform_enqueued_jobs do
        post "/api/v1/merchant/batches", params: { file: bad }, headers: headers
      end
      get "/api/v1/merchant/batches/#{json['batch']['id']}", headers: headers
      expect(json["batch"]["status"]).to eq("failed")
      expect(json["batch"]["error_message"]).to include("missing required columns")
    end

    it "requires a file" do
      post "/api/v1/merchant/batches", params: { name: "x" }, headers: headers
      expect(response).to have_http_status(:bad_request)
    end

    it "refuses admins without a merchant" do
      post "/api/v1/merchant/batches", params: { file: fixture_file_upload("orders.csv", "text/csv") }, headers: auth_headers(create(:user, :admin))
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/merchant/batches" do
    it "lists only the caller's merchant batches, newest first" do
      older = create(:batch, merchant: user.merchant, name: "Older", created_at: 2.days.ago)
      newer = create(:batch, merchant: user.merchant, name: "Newer")
      create(:batch, name: "Someone else's")

      get "/api/v1/merchant/batches", headers: headers
      expect(json["batches"].map { |b| b["name"] }).to eq([newer.name, older.name])
    end

    it "hides another merchant's batch" do
      other = create(:batch)
      get "/api/v1/merchant/batches/#{other.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
