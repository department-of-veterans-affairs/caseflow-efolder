class AddFromApiToDownloads < ActiveRecord::Migration
  def change
    add_column :downloads, :from_api, :boolean, default: false
  end
end
