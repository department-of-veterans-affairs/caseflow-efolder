class AddTempIdToRecords < ActiveRecord::Migration[5.2]
  def up
    add_column :records, :temp_id, :bigint
  end

  def down
    remove_column :records, :temp_id
  end
end
