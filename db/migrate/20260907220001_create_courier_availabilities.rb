class CreateCourierAvailabilities < ActiveRecord::Migration[7.2]
  def change
    create_table :courier_availabilities do |t|
      t.references :courier, null: false, foreign_key: true
      t.date :availability_date, null: false
      t.timestamps
    end

    add_index :courier_availabilities, [ :courier_id, :availability_date ], unique: true
    add_index :courier_availabilities, :availability_date
  end
end
