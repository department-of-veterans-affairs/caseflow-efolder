class RenameManifestStatusesToManifestSources < ActiveRecord::Migration
  def change
    rename_table :manifest_statuses, :manifest_sources
  end
end
