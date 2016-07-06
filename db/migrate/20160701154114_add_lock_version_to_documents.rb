class AddLockVersionToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :lock_version, :integer
  end
end
