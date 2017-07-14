class AddFileNumberUserIndexToDownloads < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :downloads, [:file_number, :user_id], algorithm: :concurrently
  end
end
