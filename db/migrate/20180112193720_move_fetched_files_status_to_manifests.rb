class MoveFetchedFilesStatusToManifests < ActiveRecord::Migration
  def change
    safety_assured { add_column :manifests, :fetched_files_status, :integer, default: 0 }
    add_column :manifests, :fetched_files_at, :datetime
    remove_column :files_downloads, :status, :integer
    remove_column :files_downloads, :fetched_files_at, :datetime
    add_column :files_downloads, :requested_zip_at, :datetime
  end
end
