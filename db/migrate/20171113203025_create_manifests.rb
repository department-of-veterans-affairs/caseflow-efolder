class CreateManifests < ActiveRecord::Migration
  def change
    create_table :manifests do |t|
      t.string   "file_number"
      t.string   "veteran_last_name"
      t.string   "veteran_first_name"
      t.string   "veteran_last_four_ssn"
      t.integer  "zipfile_size",  limit: 8  # The value will be updated based on the changes to the documents
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
