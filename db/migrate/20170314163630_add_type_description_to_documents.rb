class AddTypeDescriptionToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :type_description, :string
  end
end
