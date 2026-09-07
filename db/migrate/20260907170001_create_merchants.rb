class CreateMerchants < ActiveRecord::Migration[7.2]
  def change
    create_table :merchants do |t|
      t.string :business_name, null: false
      t.string :slug, null: false
      t.string :contact_name
      t.string :contact_email, null: false
      t.string :phone
      t.string :pickup_address_line, null: false
      t.string :pickup_unit
      t.string :pickup_city, null: false, default: "Toronto"
      t.string :pickup_postal_code, null: false
      t.decimal :pickup_lat, precision: 10, scale: 7
      t.decimal :pickup_lng, precision: 10, scale: 7
      t.string :cutoff_time, null: false, default: "14:00"
      t.string :timezone, null: false, default: "America/Toronto"
      t.timestamps
    end
    add_index :merchants, :slug, unique: true
  end
end
