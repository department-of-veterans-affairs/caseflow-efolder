class AddIndexToTempId < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    add_index :records, :temp_id, unique: true, algorithm: :concurrently
  end

  def down
    remove_index :records, :temp_id
  end
end
