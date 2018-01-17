class AddManifestSourceIdSeriesIdIndexToRecords < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :records, [:manifest_source_id, :series_id], algorithm: :concurrently
  end
end
