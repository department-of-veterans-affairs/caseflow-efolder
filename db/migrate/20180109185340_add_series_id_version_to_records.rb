class AddSeriesIdVersionToRecords < ActiveRecord::Migration
  def change
    add_column :records, :series_id, :string
    add_column :records, :version, :integer
  end
end
