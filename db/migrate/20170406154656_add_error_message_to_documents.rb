class AddErrorMessageToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :error_message, :text
  end
end
