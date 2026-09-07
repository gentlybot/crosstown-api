class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.references :merchant, foreign_key: true
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.string :role, null: false, default: "merchant_staff"
      t.datetime :last_signed_in_at
      t.timestamps
    end
    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"
  end
end
