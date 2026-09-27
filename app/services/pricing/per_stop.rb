module Pricing
  class PerStop
    def self.cents_for(merchant)
      merchant.per_stop_price_cents || PricingSetting.current.default_per_stop_price_cents
    end
  end
end