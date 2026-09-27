require "rails_helper"

RSpec.describe PricingSetting do
  describe ".current" do
    it "uses one database-enforced singleton record" do
      described_class.delete_all

      first = described_class.current
      second = described_class.current

      expect(first.id).to eq(described_class::SINGLETON_ID)
      expect(second.id).to eq(first.id)
      expect(described_class.count).to eq(1)
      expect { described_class.create!(id: 2) }.to raise_error(ActiveRecord::StatementInvalid)

      first.update!(default_per_stop_price_cents: 575)
      expect(second.reload.default_per_stop_price_cents).to eq(575)
    end
  end
end
