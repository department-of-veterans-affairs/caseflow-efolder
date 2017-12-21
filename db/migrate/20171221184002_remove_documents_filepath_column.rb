class RemoveDocumentsFilepathColumn < ActiveRecord::Migration
  def change
    remove_column :documents, :filepath, :string
  end
end
