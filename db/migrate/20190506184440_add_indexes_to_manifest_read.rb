class AddIndexesToManifestRead < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :manifest_sources, :manifest_id, algorithm: :concurrently
    add_index :files_downloads, :manifest_id, algorithm: :concurrently
  end
end
