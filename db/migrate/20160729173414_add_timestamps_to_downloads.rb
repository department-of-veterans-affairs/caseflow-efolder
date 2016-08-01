class AddTimestampsToDownloads < ActiveRecord::Migration
  def change
    add_column :downloads, :manifest_fetched_at, :datetime
    add_column :downloads, :started_at, :datetime
    add_column :downloads, :completed_at, :datetime

    add_index :downloads, [:completed_at], name: "downloads_completed_at"
    add_index :downloads, [:manifest_fetched_at], name: "downloads_manifest_fetched_at"
  end
end
