class CreateRecords2020 < ActiveRecord::Migration[5.2]
  def change
    create_table :record2020s do |t|
      t.integer  "manifest_source_id"
      t.integer  "status",  default: 0
      t.string   "version_id"
      t.string   "mime_type"
      t.datetime "received_at"          # VBMS and VVA timestamp
      t.string   "type_description"
      t.string   "type_id"              # It will be deprecated when we move to the VBMS new eFolder API
      t.integer  "size"                 # This field is used to keep track of document sizes
      t.string   "jro"              # VVA metadata to download document content
      t.string   "source"           # VVA metadata to download document content
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer  "conversion_status",  default: 0
      t.string   "series_id"
      t.integer  "version"
      t.datetime "upload_date"
    end
  end
end
