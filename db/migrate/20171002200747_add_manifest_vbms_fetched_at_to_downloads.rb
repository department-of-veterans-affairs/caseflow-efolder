class AddManifestVbmsFetchedAtToDownloads < ActiveRecord::Migration
  def change
    add_column :downloads, :manifest_vbms_fetched_at, :datetime
  end
end
