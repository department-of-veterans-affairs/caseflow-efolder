class AddUploadDateToRecords < ActiveRecord::Migration[5.1]
  def change
    add_column :records, :upload_date, :datetime
  end
end
