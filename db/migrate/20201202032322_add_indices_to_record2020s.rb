class AddIndicesToRecord2020s < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  def change
    add_index :record2020s, [:manifest_source_id, :series_id], algorithm: :concurrently
    add_index :record2020s, [:version_id, :manifest_source_id], unique: true, algorithm: :concurrently
  end
end
