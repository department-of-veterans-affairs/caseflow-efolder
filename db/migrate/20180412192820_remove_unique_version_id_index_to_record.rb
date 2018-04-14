class RemoveUniqueVersionIdIndexToRecord < ActiveRecord::Migration[5.1]
  def change
    remove_index :records, column: :version_id
  end
end
