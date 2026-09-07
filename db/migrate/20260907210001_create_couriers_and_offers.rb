class CreateCouriersAndOffers < ActiveRecord::Migration[7.2]
  def change
    create_table :couriers do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :phone
      t.string :vehicle_type, null: false, default: "car"
      t.string :home_fsa
      t.string :status, null: false, default: "active"
      t.timestamps
    end

    create_table :route_offers do |t|
      t.references :route, null: false, foreign_key: true
      t.references :courier, null: false, foreign_key: true
      t.string :status, null: false, default: "offered"
      t.integer :pay_cents, null: false, default: 0
      t.datetime :offered_at, null: false
      t.datetime :expires_at, null: false
      t.datetime :responded_at
      t.timestamps
    end
    add_index :route_offers, [:route_id, :courier_id], unique: true
    add_index :route_offers, [:courier_id, :status]

    change_table :routes do |t|
      t.references :courier, foreign_key: true
      t.integer :pay_cents, null: false, default: 0
      t.datetime :offered_at
      t.datetime :assigned_at
      t.datetime :started_at
      t.datetime :completed_at
    end

    change_table :route_stops do |t|
      t.string :status, null: false, default: "pending"
      t.datetime :arrived_at
      t.datetime :completed_at
      t.string :failure_reason
      t.text :note
      t.text :photo_data
    end
  end
end
