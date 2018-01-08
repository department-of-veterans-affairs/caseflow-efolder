class AddConversionStatusToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :conversion_status, :integer
  end
end
