class DeduplicateUserRecords < ActiveRecord::Migration
  # rubocop:disable Metrics/MethodLength
  def up
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

    # Replace css_ids for older user records with the newest user record's css_id casing.
    execute <<-SQL
      update users t
      set css_id = c.css_id
      from users a
      join (
        select
          max(id) max_id, upper(css_id) upper_css_id
        from users
        group by upper(css_id)
      ) b
      on upper(a.css_id) = b.upper_css_id
      join users c
      on c.id = b.max_id
      where a.css_id = t.css_id;
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
  end
  # rubocop:enable Metrics/MethodLength

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
