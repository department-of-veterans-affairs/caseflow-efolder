class AddConversionStatusToRecords < ActiveRecord::Migration
  def change
    add_column :records, :conversion_status, :integer
  end
end
