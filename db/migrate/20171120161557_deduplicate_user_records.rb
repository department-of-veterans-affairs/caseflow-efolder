class DeduplicateUserRecords < ActiveRecord::Migration
  # rubocop:disable Metrics/MethodLength
  def up
    # Run these statements as part of a single transaction for safety and thoroughness (we could potentially add
    # a new user after the delete operation took place and capitalizing each letter would then cause a primary
    # key conflict). Also, this transaction will probably be very speedy so any locking effects will be small.
    execute "begin;"

    # Update css_id field in downloads table to reference older version of duplicate user.
    execute <<-SQL
      with t as (
        select
          a.id original_id,
          b.id duplicate_id
        from users a
        join users b
          on upper(a.css_id) = upper(b.css_id)
          and a.station_id = b.station_id
          and a.created_at < b.created_at
      )
      update downloads
      set user_id = t.original_id
      from t
      where user_id = t.duplicate_id;
    SQL

    # Update css_id field in searches table to reference older version of duplicate user.
    execute <<-SQL
      with t as (
        select
          a.id original_id,
          b.id duplicate_id
        from users a
        join users b
          on upper(a.css_id) = upper(b.css_id)
          and a.station_id = b.station_id
          and a.created_at < b.created_at
      )
      update searches
      set user_id = t.original_id
      from t
      where user_id = t.duplicate_id;
    SQL

    # Delete newer duplicate user records.
    execute <<-SQL
      delete
      from users
      where id in (
        select
          b.id
        from users a
        join users b
          on upper(a.css_id) = upper(b.css_id)
          and a.station_id = b.station_id
          and a.created_at < b.created_at
      );
    SQL

    # Capitalize all css_ids in the user table.
    execute <<-SQL
      update users set css_id = upper(css_id);
    SQL

    # Commit the transaction.
    execute "commit;"
  end
  # rubocop:enable Metrics/MethodLength

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
