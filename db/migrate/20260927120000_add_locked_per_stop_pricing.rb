class AddLockedPerStopPricing < ActiveRecord::Migration[7.2]
  def change
    add_column :merchants, :per_stop_price_cents, :integer
    add_check_constraint :merchants, "per_stop_price_cents IS NULL OR per_stop_price_cents > 0", name: "merchants_per_stop_price_cents_positive"

    add_column :orders, :settled_price_cents, :integer
    add_check_constraint :orders, "settled_price_cents IS NULL OR settled_price_cents > 0", name: "orders_settled_price_cents_positive"

    create_table :pricing_settings do |t|
      t.integer :default_per_stop_price_cents, null: false, default: 500
      t.timestamps
    end
    add_check_constraint :pricing_settings, "default_per_stop_price_cents > 0", name: "pricing_settings_default_per_stop_price_positive"
  end
end