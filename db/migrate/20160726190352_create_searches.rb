class CreateSearches < ActiveRecord::Migration
  def change
    create_table :searches do |t|
      t.belongs_to :download, index: true
      t.string :file_number
      t.integer :status, default: 0
      t.string :user_station_id
      t.string :user_id
    end
  end
end
