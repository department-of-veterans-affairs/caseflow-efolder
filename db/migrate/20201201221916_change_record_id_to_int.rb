class ChangeRecordIdToInt < ActiveRecord::Migration[5.2]
  def up
    change_column :records, :id, :int, null: true
    execute "ALTER TABLE records ALTER COLUMN id DROP DEFAULT;"
    execute "DROP SEQUENCE records_id_seq;"
  end

  def down
    change_column :records, :id, :int, null: false
    execute "CREATE SEQUENCE records_id_seq;"
    execute "ALTER TABLE records ALTER id SET DEFAULT NEXTVAL('records_id_seq');"
    execute "SELECT SETVAL('records_id_seq', (SELECT MAX(id) FROM records));"
  end
end