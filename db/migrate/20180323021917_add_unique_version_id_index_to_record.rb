class AddUniqueVersionIdIndexToRecord < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :records, :version_id, unique: true, algorithm: :concurrently
  end
end
