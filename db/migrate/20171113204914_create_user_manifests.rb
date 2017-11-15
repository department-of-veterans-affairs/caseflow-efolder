class CreateUserManifests < ActiveRecord::Migration
  def change
    create_table "user_manifests" do |t|
      t.integer  "manifest_id"
      t.integer  "user_id"
      t.integer  "status", default: 0         # UI specific statuses: fetching_manifest, no_documents, etc
      t.datetime "created_at", null: false    # We can use this field to display user's history in the UI
      t.datetime "updated_at", null: false
    end
  end
end
