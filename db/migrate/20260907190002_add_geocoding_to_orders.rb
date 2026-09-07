class AddGeocodingToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :geocode_precision, :string
    add_column :orders, :geocoded_at, :datetime
    add_column :orders, :fsa, :string
  end
end
