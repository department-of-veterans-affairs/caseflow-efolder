class CreateManifestStatuses < ActiveRecord::Migration
  def change
    create_table :manifest_statuses do |t|
      t.integer  "manifest_id"
      t.integer  "status",  default: 0       # Values: success, failed, pending
      t.string   "source"                    # "VBMS" or "VVA"
      t.datetime "fetched_at"                # We will use this field to determine if manifest has expired
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
