class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.references :batch, null: false, foreign_key: true
      t.references :merchant, null: false, foreign_key: true
      t.integer :row_number, null: false
      t.string :external_id
      t.string :recipient_name
      t.string :recipient_phone
      t.string :recipient_email
      t.string :address_line
      t.string :unit
      t.string :city
      t.string :postal_code
      t.text :notes
      t.integer :quantity, null: false, default: 1
      t.boolean :leave_at_door, null: false, default: false
      t.string :status, null: false, default: "pending"
      t.jsonb :problems, null: false, default: []
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.timestamps
    end
    add_index :orders, [:batch_id, :row_number], unique: true
    add_index :orders, [:merchant_id, :status]
  end
end
