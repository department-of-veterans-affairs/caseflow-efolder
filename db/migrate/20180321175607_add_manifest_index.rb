class AddManifestIndex < ActiveRecord::Migration[5.1]
  safety_assured

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

    add_index :manifests, :file_number, unique: true
  end

  def down
    remove_index :manifests, :file_number
  end
end
