class AddIndexToUserManifests < ActiveRecord::Migration
  def change
    add_index :user_manifests, [:manifest_id, :user_id], using: :btree
  end
end
