class PricingSetting < ApplicationRecord
  validates :default_per_stop_price_cents, numericality: { only_integer: true, greater_than: 0 }

  def self.current
    first_or_create!
  end
end