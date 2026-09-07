class CreateRoutes < ActiveRecord::Migration[7.2]
  def change
    create_table :routes do |t|
      t.references :merchant, null: false, foreign_key: true
      t.date :delivery_date, null: false
      t.integer :route_number, null: false
      t.string :status, null: false, default: "planned"
      t.string :engine, null: false
      t.integer :stop_count, null: false, default: 0
      t.decimal :distance_km, precision: 8, scale: 2, null: false, default: 0
      t.integer :duration_minutes, null: false, default: 0
      t.datetime :start_at, null: false
      t.decimal :start_lat, precision: 10, scale: 7, null: false
      t.decimal :start_lng, precision: 10, scale: 7, null: false
      t.timestamps
    end
    add_index :routes, :route_number, unique: true
    add_index :routes, [:merchant_id, :delivery_date]

    create_table :route_stops do |t|
      t.references :route, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true, index: { unique: true }
      t.integer :position, null: false
      t.decimal :lat, precision: 10, scale: 7, null: false
      t.decimal :lng, precision: 10, scale: 7, null: false
      t.decimal :leg_km, precision: 8, scale: 2, null: false, default: 0
      t.datetime :eta, null: false
      t.timestamps
    end
    add_index :route_stops, [:route_id, :position], unique: true

    create_table :route_plans do |t|
      t.references :merchant, null: false, foreign_key: true
      t.references :requested_by, foreign_key: { to_table: :users }
      t.date :delivery_date, null: false
      t.string :status, null: false, default: "queued"
      t.string :engine
      t.integer :routes_count, null: false, default: 0
      t.integer :stops_count, null: false, default: 0
      t.integer :unassigned_count, null: false, default: 0
      t.string :error
      t.datetime :started_at
      t.datetime :finished_at
      t.timestamps
    end
    add_index :route_plans, [:merchant_id, :delivery_date], unique: true

    add_column :batches, :routed_count, :integer, null: false, default: 0
  end
end
