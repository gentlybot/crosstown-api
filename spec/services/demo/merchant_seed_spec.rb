require "rails_helper"

RSpec.describe Demo::MerchantSeed do
  it "seeds the complete MCP roster with contacts and usable Toronto pickup locations" do
    expect(described_class.call).to eq(24)
    expect(Merchant.count).to eq(24)
    expect(User.count).to eq(27)
    expect(described_class::MERCHANTS.pluck(:mcp_customer_id).uniq.size).to eq(24)

    described_class::MERCHANTS.each do |attrs|
      merchant = Merchant.find_by!(slug: attrs.fetch(:slug))
      expect(merchant.business_name).to eq(attrs.fetch(:business_name))
      expect(merchant.contact_name).to eq(attrs.fetch(:contact_name))
      expect(merchant.contact_email).to eq(attrs.fetch(:contact_email))
      expect(merchant.users.find_by!(email: merchant.contact_email)).to have_attributes(
        name: merchant.contact_name, role: "merchant_admin"
      )
      location = Geocoding::AddressBank.lookup(merchant.pickup_address_line, city: merchant.pickup_city)
      expect(location).to be_present
      expect(location.fsa).to eq(merchant.pickup_postal_code.first(3))
      expect(merchant.pickup_lat.to_f).to be_within(0.01).of(location.lat)
      expect(merchant.pickup_lng.to_f).to be_within(0.01).of(location.lng)
    end
  end

  it "keeps existing IDs, passwords, delivery data, and unrelated merchants on repeat runs" do
    bloom = create(:merchant, slug: "bloom-and-stem")
    maya = create(:user, merchant: bloom, email: "maya@bloomandstem.example", password: "changed-password")
    batch = create(:batch, merchant: bloom, created_by: maya)
    outsider = create(:merchant, slug: "another-shop")
    outsider_attrs = outsider.attributes
    password_digest = maya.password_digest

    described_class.call
    ids = Merchant.order(:slug).pluck(:slug, :id)
    casey = User.find_by!(email: "casey.cole@bloom.example")
    casey.update!(password: "changed-contact-password")
    users = User.order(:email).pluck(:email, :id, :password_digest)

    described_class.call
    expect(Merchant.order(:slug).pluck(:slug, :id)).to eq(ids)
    expect(User.order(:email).pluck(:email, :id, :password_digest)).to eq(users)
    expect(bloom.reload.business_name).to eq("Bloom & Stem")
    expect(maya.reload.password_digest).to eq(password_digest)
    expect(batch.reload).to have_attributes(merchant_id: bloom.id, created_by_id: maya.id)
    expect(outsider.reload.attributes).to eq(outsider_attrs)
  end

  it "keeps the original admins as allowance owners on a fresh database" do
    described_class.call
    DeliveryAllowances::DemoSeed.call
    described_class.call
    DeliveryAllowances::DemoSeed.call

    bloom = Merchant.find_by!(slug: "bloom-and-stem")
    allowance = bloom.delivery_allowances.find_by!(service_type: "same_day")
    expect(allowance.delivery_reservations.sum(:units)).to eq(320)
    expect(allowance.delivery_reservations.joins(:user).pluck("users.email")).to contain_exactly(
      "maya@bloomandstem.example", "sam@bloomandstem.example"
    )
    sam = User.find_by!(email: "sam@bloomandstem.example")
    expect(DeliveryAllowances::Balance.new(sam).entry("same_day")[:available_to_you]).to eq(5)
    bread = Merchant.find_by!(slug: "corner-loaf")
    expect(bread.users.merchant_admin.order(:id).first.email).to eq("devin@cornerloaf.example")
  end
end
