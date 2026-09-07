class CreateBatches < ActiveRecord::Migration[7.2]
  def change
    create_table :batches do |t|
      t.references :merchant, null: false, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.date :delivery_date, null: false
      t.string :status, null: false, default: "importing"
      t.string :source, null: false, default: "csv"
      t.string :original_filename
      t.text :raw_csv
      t.integer :row_count, null: false, default: 0
      t.integer :ready_count, null: false, default: 0
      t.integer :problem_count, null: false, default: 0
      t.datetime :imported_at
      t.string :error_message
      t.timestamps
    end
    add_index :batches, [:merchant_id, :created_at]
  end
end
