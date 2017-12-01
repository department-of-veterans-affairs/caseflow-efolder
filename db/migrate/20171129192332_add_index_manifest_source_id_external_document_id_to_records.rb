class AddIndexManifestSourceIdExternalDocumentIdToRecords < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :records, [:manifest_source_id, :external_document_id], algorithm: :concurrently, using: :btree
  end
end
