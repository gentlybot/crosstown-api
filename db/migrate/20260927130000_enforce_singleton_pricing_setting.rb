class EnforceSingletonPricingSetting < ActiveRecord::Migration[7.2]
  SINGLETON_ID = 1

  def up
    execute <<~SQL.squish
      DELETE FROM pricing_settings
      WHERE id <> (SELECT MIN(id) FROM pricing_settings)
    SQL
    execute "UPDATE pricing_settings SET id = #{SINGLETON_ID} WHERE id <> #{SINGLETON_ID}"
    add_check_constraint :pricing_settings, "id = #{SINGLETON_ID}", name: "pricing_settings_singleton_id"
  end

  def down
    remove_check_constraint :pricing_settings, name: "pricing_settings_singleton_id"
  end
end
