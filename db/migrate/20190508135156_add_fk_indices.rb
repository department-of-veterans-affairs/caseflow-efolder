class AddFkIndices < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :documents, :download_id, algorithm: :concurrently
  end
end
