class DropRecordsTable < ActiveRecord::Migration[5.2]
  def change
    drop_table :records
  end
end
