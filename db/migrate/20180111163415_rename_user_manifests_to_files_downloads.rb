class RenameUserManifestsToFilesDownloads < ActiveRecord::Migration
  def change
    rename_table :user_manifests, :files_downloads
  end
end
