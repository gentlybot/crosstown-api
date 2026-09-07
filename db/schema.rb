# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_09_07_200001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "address_bank_entries", force: :cascade do |t|
    t.integer "street_number", null: false
    t.string "street_name", null: false
    t.string "street_display", null: false
    t.string "city", default: "Toronto", null: false
    t.string "fsa", null: false
    t.decimal "lat", precision: 10, scale: 7, null: false
    t.decimal "lng", precision: 10, scale: 7, null: false
    t.string "source", default: "seed", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["street_name", "city", "street_number"], name: "index_address_bank_on_street_city_number", unique: true
  end

  create_table "batches", force: :cascade do |t|
    t.bigint "merchant_id", null: false
    t.bigint "created_by_id"
    t.string "name", null: false
    t.date "delivery_date", null: false
    t.string "status", default: "importing", null: false
    t.string "source", default: "csv", null: false
    t.string "original_filename"
    t.text "raw_csv"
    t.integer "row_count", default: 0, null: false
    t.integer "ready_count", default: 0, null: false
    t.integer "problem_count", default: 0, null: false
    t.datetime "imported_at"
    t.string "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "routed_count", default: 0, null: false
    t.index ["created_by_id"], name: "index_batches_on_created_by_id"
    t.index ["merchant_id", "created_at"], name: "index_batches_on_merchant_id_and_created_at"
    t.index ["merchant_id"], name: "index_batches_on_merchant_id"
  end

  create_table "merchants", force: :cascade do |t|
    t.string "business_name", null: false
    t.string "slug", null: false
    t.string "contact_name"
    t.string "contact_email", null: false
    t.string "phone"
    t.string "pickup_address_line", null: false
    t.string "pickup_unit"
    t.string "pickup_city", default: "Toronto", null: false
    t.string "pickup_postal_code", null: false
    t.decimal "pickup_lat", precision: 10, scale: 7
    t.decimal "pickup_lng", precision: 10, scale: 7
    t.string "cutoff_time", default: "14:00", null: false
    t.string "timezone", default: "America/Toronto", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_merchants_on_slug", unique: true
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "batch_id", null: false
    t.bigint "merchant_id", null: false
    t.integer "row_number", null: false
    t.string "external_id"
    t.string "recipient_name"
    t.string "recipient_phone"
    t.string "recipient_email"
    t.string "address_line"
    t.string "unit"
    t.string "city"
    t.string "postal_code"
    t.text "notes"
    t.integer "quantity", default: 1, null: false
    t.boolean "leave_at_door", default: false, null: false
    t.string "status", default: "pending", null: false
    t.jsonb "problems", default: [], null: false
    t.decimal "lat", precision: 10, scale: 7
    t.decimal "lng", precision: 10, scale: 7
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "geocode_precision"
    t.datetime "geocoded_at"
    t.string "fsa"
    t.index ["batch_id", "row_number"], name: "index_orders_on_batch_id_and_row_number", unique: true
    t.index ["batch_id"], name: "index_orders_on_batch_id"
    t.index ["merchant_id", "status"], name: "index_orders_on_merchant_id_and_status"
    t.index ["merchant_id"], name: "index_orders_on_merchant_id"
  end

  create_table "route_plans", force: :cascade do |t|
    t.bigint "merchant_id", null: false
    t.bigint "requested_by_id"
    t.date "delivery_date", null: false
    t.string "status", default: "queued", null: false
    t.string "engine"
    t.integer "routes_count", default: 0, null: false
    t.integer "stops_count", default: 0, null: false
    t.integer "unassigned_count", default: 0, null: false
    t.string "error"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id", "delivery_date"], name: "index_route_plans_on_merchant_id_and_delivery_date", unique: true
    t.index ["merchant_id"], name: "index_route_plans_on_merchant_id"
    t.index ["requested_by_id"], name: "index_route_plans_on_requested_by_id"
  end

  create_table "route_stops", force: :cascade do |t|
    t.bigint "route_id", null: false
    t.bigint "order_id", null: false
    t.integer "position", null: false
    t.decimal "lat", precision: 10, scale: 7, null: false
    t.decimal "lng", precision: 10, scale: 7, null: false
    t.decimal "leg_km", precision: 8, scale: 2, default: "0.0", null: false
    t.datetime "eta", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_route_stops_on_order_id", unique: true
    t.index ["route_id", "position"], name: "index_route_stops_on_route_id_and_position", unique: true
    t.index ["route_id"], name: "index_route_stops_on_route_id"
  end

  create_table "routes", force: :cascade do |t|
    t.bigint "merchant_id", null: false
    t.date "delivery_date", null: false
    t.integer "route_number", null: false
    t.string "status", default: "planned", null: false
    t.string "engine", null: false
    t.integer "stop_count", default: 0, null: false
    t.decimal "distance_km", precision: 8, scale: 2, default: "0.0", null: false
    t.integer "duration_minutes", default: 0, null: false
    t.datetime "start_at", null: false
    t.decimal "start_lat", precision: 10, scale: 7, null: false
    t.decimal "start_lng", precision: 10, scale: 7, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id", "delivery_date"], name: "index_routes_on_merchant_id_and_delivery_date"
    t.index ["merchant_id"], name: "index_routes_on_merchant_id"
    t.index ["route_number"], name: "index_routes_on_route_number", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.bigint "merchant_id"
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "name", null: false
    t.string "role", default: "merchant_staff", null: false
    t.datetime "last_signed_in_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["merchant_id"], name: "index_users_on_merchant_id"
  end

  add_foreign_key "batches", "merchants"
  add_foreign_key "batches", "users", column: "created_by_id"
  add_foreign_key "orders", "batches"
  add_foreign_key "orders", "merchants"
  add_foreign_key "route_plans", "merchants"
  add_foreign_key "route_plans", "users", column: "requested_by_id"
  add_foreign_key "route_stops", "orders"
  add_foreign_key "route_stops", "routes"
  add_foreign_key "routes", "merchants"
  add_foreign_key "users", "merchants"
end
