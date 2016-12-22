class RemoveUserIdFromSearchesAndDownloads < ActiveRecord::Migration
  def change
    remove_column :searches, :user_id
    remove_column :downloads, :user_id
  end
end
