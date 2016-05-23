class AddUserToDownloads < ActiveRecord::Migration
  def change
    add_column :downloads, :user_station_id, :string
    add_column :downloads, :user_id, :string
    add_index  :downloads, [:user_id, :user_station_id]
  end
end
