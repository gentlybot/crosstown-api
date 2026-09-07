require "rails_helper"

RSpec.describe Batches::CsvImporter do
  let(:merchant) { create(:merchant) }
  let(:batch) { create(:batch, merchant: merchant) }

  it "creates one order per row, flags problems, and settles the batch status" do
    described_class.new(batch).call
    batch.reload

    expect(batch.row_count).to eq(7)
    expect(batch.problem_count).to eq(3)
    expect(batch.ready_count).to eq(4)
    expect(batch.status).to eq("needs_review")
    expect(batch.imported_at).to be_present

    by_id = batch.orders.index_by(&:external_id)
    expect(by_id["1001"].problems).to be_empty
    expect(by_id["1001"].leave_at_door).to be(true)
    expect(by_id["1002"].postal_code).to eq("M6J 2J8"), "postal codes are upcased and spaced"
    expect(by_id["1002"].quantity).to eq(2)
    expect(by_id["1004"].problems).to eq(["Address is missing"])
    expect(by_id["1005"].problems).to eq(["Postal code does not look valid"])
    expect(by_id["1006"].problems).to eq(["Quantity must be a whole number of 1 or more"])
    expect(by_id["1006"].city).to eq("Toronto"), "blank city falls back to the merchant's city"
  end

  it "marks rows without any contact method" do
    batch.update!(raw_csv: "name,address,postal_code\nPat Lee,22 Palmerston Ave,M6J 2J1\n")
    described_class.new(batch).call
    expect(batch.orders.first.problems).to eq(["Phone or email is required"])
  end

  it "places rows against the address bank" do
    described_class.new(batch).call
    by_id = batch.orders.index_by(&:external_id)
    expect(by_id["1001"].lat).to be_within(0.01).of(43.647)
    expect(by_id["1001"].lng).to be_within(0.01).of(-79.411)
    expect(by_id["1001"].geocode_precision).to eq("exact")
    expect(by_id["1001"].fsa).to eq("M6J")
    expect(by_id["1004"].lat).to be_nil, "rows without an address are not looked up"
  end

  it "flags an address the bank does not know" do
    batch.update!(raw_csv: "name,phone,address,postal_code\nPat Lee,416-555-0100,9 Nowhere Cres,M6J 2J1\n")
    described_class.new(batch).call
    order = batch.orders.first
    expect(order.problems).to eq(["Address not found"])
    expect(order.geocode_precision).to eq("none")
  end

  it "flags a postal code from the wrong part of town" do
    batch.update!(raw_csv: "name,phone,address,postal_code\nPat Lee,416-555-0100,22 Palmerston Ave,M4M 1A1\n")
    described_class.new(batch).call
    expect(batch.orders.first.problems).to eq(["Postal code M4M does not match the address, which is in M6J"])
    expect(batch.orders.first.lat).to be_present, "the row is still placed"
  end

  it "rejects files missing a required column" do
    batch.update!(raw_csv: "name,phone\nPat Lee,416-555-0100\n")
    expect { described_class.new(batch).call }
      .to raise_error(described_class::InvalidFile, /missing required columns: Address, Postal code/)
  end

  it "rejects a header-only file" do
    batch.update!(raw_csv: "name,address,postal_code\n")
    expect { described_class.new(batch).call }.to raise_error(described_class::InvalidFile, /no orders/)
  end

  it "refuses to re-import a batch whose orders are already routed" do
    described_class.new(batch).call
    route = Route.create!(merchant: merchant, delivery_date: batch.delivery_date, engine: "savings", start_at: Time.current, start_lat: 43.6, start_lng: -79.4)
    order = batch.orders.ready.first
    RouteStop.create!(route: route, order: order, position: 1, lat: order.lat, lng: order.lng, eta: Time.current)
    expect { described_class.new(batch).call }.to raise_error(described_class::InvalidFile, /already has routed orders/)
  end

  it "is idempotent when rerun" do
    2.times { described_class.new(batch).call }
    expect(batch.orders.count).to eq(7)
  end
end
