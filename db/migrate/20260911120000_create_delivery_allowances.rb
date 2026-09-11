class CreateDeliveryAllowances < ActiveRecord::Migration[7.2]
  def change
    create_table :delivery_allowances do |t|
      t.references :merchant, null: false, foreign_key: true
      t.string :service_type, null: false
      t.integer :monthly_limit, null: false
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end
    add_index :delivery_allowances, [ :merchant_id, :service_type ], unique: true
    add_check_constraint :delivery_allowances, "monthly_limit >= 0"

    create_table :staff_delivery_limits do |t|
      t.references :delivery_allowance, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :monthly_limit, null: false
      t.timestamps
    end
    add_index :staff_delivery_limits, [ :delivery_allowance_id, :user_id ], unique: true
    add_check_constraint :staff_delivery_limits, "monthly_limit >= 0"

    create_table :delivery_reservations do |t|
      t.references :delivery_allowance, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :period_start, null: false
      t.integer :units, null: false
      t.string :request_key, null: false
      t.datetime :cancelled_at
      t.timestamps
    end
    add_index :delivery_reservations, [ :user_id, :request_key ], unique: true
    add_index :delivery_reservations, [ :delivery_allowance_id, :period_start ], name: "index_delivery_reservations_on_allowance_period"
    add_check_constraint :delivery_reservations, "units > 0"
  end
end
