class AddDurationFieldsToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :started_at, :datetime
    add_column :documents, :completed_at, :datetime
  end
end
