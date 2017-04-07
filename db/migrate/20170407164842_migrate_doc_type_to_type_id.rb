class MigrateDocTypeToTypeId < ActiveRecord::Migration
  def change
    say_with_time("Migrating doc_type to type_id in the documents table") do
      ActiveRecord::Base.connection.execute("UPDATE documents SET type_id = doc_type")
    end
  end
end
