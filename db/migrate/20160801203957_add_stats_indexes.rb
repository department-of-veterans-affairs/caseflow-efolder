class AddStatsIndexes < ActiveRecord::Migration
  def change
    add_column :searches, :created_at, :datetime

    add_index :searches, [:status, :created_at], name: "searches_status_created_at"
    add_index :searches, [:created_at], name: "searches_created_at"
    add_index :documents, [:download_status, :completed_at], name: "searches_download_status_completed_at"
  end
end
