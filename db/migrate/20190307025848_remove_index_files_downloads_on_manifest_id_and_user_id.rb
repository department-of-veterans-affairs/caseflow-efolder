class RemoveIndexFilesDownloadsOnManifestIdAndUserId < ActiveRecord::Migration[5.1]
  def change
    remove_index :files_downloads, ["manifest_id", "user_id"]
  end
end
