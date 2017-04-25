class SplitDocumentsStatusCreatedAtIndex < ActiveRecord::Migration
  def change
    add_index "documents", ["download_status"], name: "index_documents_on_download_status", using: :btree
    add_index "documents", ["completed_at"], name: "index_documents_on_completed_at", using: :btree
    remove_index "documents", name: "searches_download_status_completed_at"
  end
end
