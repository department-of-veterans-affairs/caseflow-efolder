class AddUniqueVersionIdManifestIdIndexToRecord < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :records, [:version_id, :manifest_source_id], unique: true, algorithm: :concurrently
  end
end
