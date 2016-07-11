class AddVeteranNameToDownloads < ActiveRecord::Migration
  def change
    add_column :downloads, :veteran_name, :string
  end
end
