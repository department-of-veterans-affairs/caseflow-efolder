class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
			t.belongs_to :download, index: true
			t.integer :download_status
			t.string :document_id
			t.integer :download_status
			t.string :filename
			t.string :doc_type
			t.string :source
			t.string :mime_type
			t.datetime :received_at
      t.timestamps null: false
    end
  end
end
