class MigrateDocTypeToTypeId < ActiveRecord::Migration
  def change
    say_with_time("Migrating doc_type to type_id in documents table") do
      pbar = ProgressBar.new(total: Document.find(:all).size)
      Document.find_each do |d|
        pbar.increment
        d.update(type_id: d.doc_type) unless d.type_id
      end
    end
  end
end
