class AddManifestVvaFetchedAtToDownloads < ActiveRecord::Migration
  def change
    add_column :downloads, :manifest_vva_fetched_at, :datetime
  end
end
