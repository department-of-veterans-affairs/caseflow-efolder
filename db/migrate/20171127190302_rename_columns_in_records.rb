class RenameColumnsInRecords < ActiveRecord::Migration
  def change
    rename_column :records, :vva_source, :source
    rename_column :records, :vva_jro, :jro
  end
end
