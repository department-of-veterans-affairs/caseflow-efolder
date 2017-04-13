class RemoveDocTypeFromDocuments < ActiveRecord::Migration
  def change
    remove_column :documents, :doc_type
  end
end
