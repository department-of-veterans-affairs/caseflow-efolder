class CreateDownloads < ActiveRecord::Migration
  def change
    create_table :downloads do |t|
      t.string :request_id
      t.string :file_number
      t.string :state

      t.timestamps null: false
    end
  end
end
