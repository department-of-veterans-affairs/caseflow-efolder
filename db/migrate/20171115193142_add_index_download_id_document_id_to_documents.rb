class AddIndexDownloadIdDocumentIdToDocuments < ActiveRecord::Migration
  def change
    add_index :documents, [:download_id, :document_id], using: :btree
    remove_index :documents, [:download_id]
  end
end
