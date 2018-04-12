class RemoveManifestIdVersionIdIndexToRecord < ActiveRecord::Migration[5.1]
  def change
    remove_index :records, column: [:manifest_source_id, :version_id]
  end
end
