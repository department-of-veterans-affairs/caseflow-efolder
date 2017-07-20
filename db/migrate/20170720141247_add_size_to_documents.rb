class AddSizeToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :size, :integer
  end
end
