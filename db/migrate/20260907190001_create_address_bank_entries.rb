class CreateAddressBankEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :address_bank_entries do |t|
      t.integer :street_number, null: false
      t.string :street_name, null: false   # normalized, e.g. "palmerston ave"
      t.string :street_display, null: false # as printed, e.g. "Palmerston Ave"
      t.string :city, null: false, default: "Toronto"
      t.string :fsa, null: false            # first three characters of the postal code
      t.decimal :lat, precision: 10, scale: 7, null: false
      t.decimal :lng, precision: 10, scale: 7, null: false
      t.string :source, null: false, default: "seed"
      t.timestamps
    end
    add_index :address_bank_entries, [:street_name, :city, :street_number], unique: true, name: "index_address_bank_on_street_city_number"
  end
end
