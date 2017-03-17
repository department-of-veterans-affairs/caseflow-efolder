class AddTypeIdToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :type_id, :string
  end
end
