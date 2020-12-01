class ChangeRecordIdToBigint < ActiveRecord::Migration[5.2]
  def up
    change_column :records, :id, :bigint
  end

  def down
    change_column :records, :id, :integer
  end
end
