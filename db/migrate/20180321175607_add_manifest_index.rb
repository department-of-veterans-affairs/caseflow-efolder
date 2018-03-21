class AddManifestIndex < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :manifests, :file_number, unique: true, algorithm: :concurrently
  end
end
