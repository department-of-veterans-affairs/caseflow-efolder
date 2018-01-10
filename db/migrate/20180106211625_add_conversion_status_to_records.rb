class AddConversionStatusToRecords < ActiveRecord::Migration
  def change
    safety_assured { add_column :records, :conversion_status, :integer, default: 0 }
  end
end
