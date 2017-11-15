class AddIndexToManifests < ActiveRecord::Migration
  def change
    add_index :manifests, [:file_number], using: :btree
  end
end
