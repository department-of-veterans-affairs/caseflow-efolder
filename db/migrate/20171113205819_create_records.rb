class CreateRecords < ActiveRecord::Migration
  def change
    create_table "records" do |t|
      t.integer  "manifest_id"
      t.integer  "status",  default: 0
      t.string   "external_document_id"
      t.string   "mime_type"
      t.datetime "received_at"          # VBMS and VVA timestamp
      t.string   "type_description"
      t.string   "type_id"              # It will be deprecated when we move to the VBMS new eFolder API
      t.integer  "size"                 # This field is used to keep track of document sizes
      t.string   "vva_jro"              # VVA metadata to download document content
      t.string   "vva_source"           # VVA metadata to download document content
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
