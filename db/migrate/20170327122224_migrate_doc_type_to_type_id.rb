class MigrateDocTypeToTypeId < ActiveRecord::Migration
  def change
    Document.find_each do |d|
      d.update(type_id: d.doc_type) unless d.type_id
    end
  end
end
