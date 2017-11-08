class AddConvertedMimeTypeToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :converted_mime_type, :string
  end
end
