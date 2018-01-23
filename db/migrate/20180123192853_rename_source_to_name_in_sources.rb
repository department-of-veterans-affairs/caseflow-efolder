class RenameSourceToNameInSources < ActiveRecord::Migration
  def change
    rename_column :manifest_sources, :source, :name
  end
end
