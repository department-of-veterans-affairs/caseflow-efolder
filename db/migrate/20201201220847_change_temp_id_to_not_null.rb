class ChangeTempIdToNotNull < ActiveRecord::Migration[5.2]
  def up
    change_column :records, :temp_id, :bigint, null: false
  end

  def down
    change_column :records, :temp_id, :bigint, null: true
  end
end
