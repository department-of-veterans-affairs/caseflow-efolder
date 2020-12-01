class ChangeTempIdToPrimaryKey < ActiveRecord::Migration[5.2]
  def up
    ActiveRecord::Base.transaction do
      # Remove our primary key on id
      execute "ALTER TABLE records DROP CONSTRAINT records_pkey;"
      # Add temp_id as the primary key, using index from a previous migration for performace gains if it exists
      execute "ALTER TABLE records ADD CONSTRAINT records_pkey PRIMARY KEY USING INDEX index_records_on_temp_id;"
      # Ensure we auto increment our primary key
      execute "CREATE SEQUENCE records_temp_id_seq;"
      execute "ALTER TABLE records ALTER temp_id SET DEFAULT NEXTVAL('records_temp_id_seq');"
      execute "SELECT SETVAL('records_temp_id_seq', (SELECT MAX(temp_id) FROM records));"
    end
  end

  def down
    ActiveRecord::Base.transaction do
      # Remove our primary key on temp_id
      execute "ALTER TABLE records DROP CONSTRAINT records_pkey;"
      # Add temp_id as the primary key, Don't have an index here to rely on
      execute "ALTER TABLE records ADD PRIMARY KEY (id);"
      # Add back the index that gets removed when adding a primary key on an index
      add_index :records, :temp_id, unique: true
    end
  end
end