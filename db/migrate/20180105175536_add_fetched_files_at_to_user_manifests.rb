class AddFetchedFilesAtToUserManifests < ActiveRecord::Migration
  def change
    add_column :user_manifests, :fetched_files_at, :datetime
  end
end
