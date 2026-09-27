class PricingSetting < ApplicationRecord
  SINGLETON_ID = 1

  validates :default_per_stop_price_cents, numericality: { only_integer: true, greater_than: 0 }

  def self.current
    create_or_find_by!(id: SINGLETON_ID)
  end
end
