class RenameFilenameToVbmsFilenameOnDocuments < ActiveRecord::Migration
  def change
    rename_column :documents, :filename, :vbms_filename
  end
end
