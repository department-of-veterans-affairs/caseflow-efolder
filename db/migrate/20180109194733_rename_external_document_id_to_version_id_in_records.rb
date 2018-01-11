class RenameExternalDocumentIdToVersionIdInRecords < ActiveRecord::Migration
  def change
    rename_column :records, :external_document_id, :version_id
  end
end
