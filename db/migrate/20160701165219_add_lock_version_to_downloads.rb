class AddLockVersionToDownloads < ActiveRecord::Migration
  def change
    add_column :downloads, :lock_version, :integer
  end
end
