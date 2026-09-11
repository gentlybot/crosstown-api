require "rails_helper"

RSpec.describe DeliveryAllowances::DemoSeed do
  let!(:bloom) { create(:merchant, slug: "bloom-and-stem") }
  let!(:bread) { create(:merchant, slug: "corner-loaf") }
  let!(:maya) { create(:user, merchant: bloom) }
  let!(:sam) { create(:user, merchant: bloom, role: "merchant_staff", email: "sam@bloomandstem.example") }
  let!(:devin) { create(:user, merchant: bread) }

  it "seeds all four buckets and the shared versus personal limit cases" do
    described_class.call
    rows = DeliveryAllowances::Balance.new(sam).call[:allowances].index_by { |row| row[:service_type] }
    expect(rows["same_day"]).to include(available_to_you: 5)
    expect(rows["same_day"][:merchant]).to eq(limit: 500, used: 320, remaining: 180)
    expect(rows["next_day"][:personal][:limit]).to be_nil
    expect(rows["return_pickup"][:blocked_by]).to eq([ "personal_limit" ])
    expect(rows["redelivery"][:blocked_by]).to eq([ "merchant_limit" ])
    expect(DeliveryAllowances::Balance.new(devin).entry("return_pickup")[:enabled]).to eq(false)
  end

  it "preserves activity on ordinary seeding and restores it only on explicit reset" do
    described_class.call
    count = DeliveryReservation.count
    DeliveryAllowances::Reserve.new(sam, service_type: "same_day", units: 2, request_key: "extra").call
    described_class.call
    expect(DeliveryReservation.count).to eq(count + 1)
    expect(DeliveryAllowances::Balance.new(sam).entry("same_day")[:available_to_you]).to eq(3)
    described_class.call(reset: true)
    described_class.call(reset: true)
    expect(DeliveryReservation.count).to eq(count)
    expect(DeliveryAllowances::Balance.new(sam).entry("same_day")[:available_to_you]).to eq(5)
  end

  it "preserves other merchants and previous months during reset" do
    described_class.call
    old = sam.delivery_reservations.first!
    old.update!(period_start: old.period_start.prev_month, request_key: "previous-month")
    outsider = create(:user)
    allowance = outsider.merchant.delivery_allowances.create!(service_type: "same_day", monthly_limit: 20)
    reserve = DeliveryAllowances::Reserve.new(outsider, service_type: "same_day", units: 2, request_key: "other-merchant").call
    described_class.call(reset: true)
    expect(old.reload.units).to eq(75)
    expect(reserve.reload.units).to eq(2)
    expect(allowance.reload.monthly_limit).to eq(20)
  end
end
