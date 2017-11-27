class RenameManifestIdToManifestSourceIdInRecords < ActiveRecord::Migration
  def change
    rename_column :records, :manifest_id, :manifest_source_id
  end
end
