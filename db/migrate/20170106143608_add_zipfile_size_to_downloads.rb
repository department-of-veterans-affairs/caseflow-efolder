class AddZipfileSizeToDownloads < ActiveRecord::Migration
  def change
    add_column :downloads, :zipfile_size, :integer, limit: 8
  end
end
