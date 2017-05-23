class AddVvaFieldsToDocument < ActiveRecord::Migration
  def change
    add_column :documents, :vva, :boolean, default: false, null: false
    add_column :documents, :jro, :string
    add_column :documents, :ssn, :string
  end
end
