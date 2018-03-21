class RemoveDuplicateManifests < ActiveRecord::Migration[5.1]
  def up
    manifest_exists_for_file_number = {}
    manifests_to_remove = []

    Manifest.find_each do |manifest|
      if manifest_exists_for_file_number[manifest[:file_number]]
        manifests_to_remove.push(manifest.id)
      end
      manifest_exists_for_file_number[manifest[:file_number]] = true
    end

    Manifest.where(id: manifests_to_remove).destroy_all
  end

  def down
    # Do nothing if we are rolling back. It's not reversible, but not an error to rollback either.
  end
end
