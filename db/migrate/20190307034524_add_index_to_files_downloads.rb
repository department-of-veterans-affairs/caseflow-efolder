class AddIndexToFilesDownloads < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :files_downloads, ["manifest_id", "user_id"], unique: true, algorithm: :concurrently
  end
end
