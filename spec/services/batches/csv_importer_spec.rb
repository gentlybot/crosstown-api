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
    batch.update!(raw_csv: "name,address,postal_code\nPat Lee,1 Yonge St,M5E 1E5\n")
    described_class.new(batch).call
    expect(batch.orders.first.problems).to eq(["Phone or email is required"])
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

  it "is idempotent when rerun" do
    2.times { described_class.new(batch).call }
    expect(batch.orders.count).to eq(7)
  end
end
