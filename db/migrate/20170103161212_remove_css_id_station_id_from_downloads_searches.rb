class RemoveCssIdStationIdFromDownloadsSearches < ActiveRecord::Migration
  def up
    remove_column :searches, :user_station_id
    remove_column :searches, :css_id
    remove_column :searches, :email

    remove_column :downloads, :user_station_id
    remove_column :downloads, :css_id
  end

  def down
    add_column :searches, :user_station_id, :string
    add_column :searches, :css_id, :string
    add_column :searches, :email, :string

    add_column :downloads, :user_station_id, :string
    add_column :downloads, :css_id, :string
  end
end
