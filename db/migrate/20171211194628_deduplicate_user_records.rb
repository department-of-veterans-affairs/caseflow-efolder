class DeduplicateUserRecords < ActiveRecord::Migration
  # rubocop:disable Metrics/MethodLength
  def up
    # Update css_id field in downloads table to reference newest version of duplicate user.
    execute <<-SQL
      with t as (
        select
          a.id previous_id,
          b.true_id
        from users a
        join (
          select
            distinct upper(css_id) upper_css_id,
            station_id,
            max(id) true_id
          from users
          group by
            upper(css_id),
            station_id
        ) b
          on upper(a.css_id) = b.upper_css_id
          and a.station_id = b.station_id
      )
      update downloads
      set user_id = t.true_id
      from t
      where user_id = t.previous_id;
    SQL

    # Update css_id field in searches table to reference newest version of duplicate user.
    execute <<-SQL
      with t as (
        select
          a.id previous_id,
          b.true_id
        from users a
        join (
          select
            distinct upper(css_id) upper_css_id,
            station_id,
            max(id) true_id
          from users
          group by
            upper(css_id),
            station_id
        ) b
          on upper(a.css_id) = b.upper_css_id
          and a.station_id = b.station_id
      )
      update searches
      set user_id = t.true_id
      from t
      where user_id = t.previous_id;
    SQL

    # Set the created_at timestamp to the created_at timestamp of the oldest duplicate user record.
    execute <<-SQL
      with t as (
        select
          a.id previous_id,
          b.original_creation
        from users a
        join (
          select
            distinct upper(css_id) upper_css_id,
            station_id,
            min(created_at) original_creation
          from users
          group by
            upper(css_id),
            station_id
        ) b
          on upper(a.css_id) = b.upper_css_id
          and a.station_id = b.station_id
      )
      update users
      set created_at = t.original_creation
      from t
      where id = t.previous_id;
    SQL

    # Delete all but the newest duplicate user records.
    execute <<-SQL
      delete
      from users
      where id in (
        select
          a.id
        from users a
        join (
          select
            distinct upper(css_id) upper_css_id,
            station_id,
            max(id) true_id
          from users
          group by
            upper(css_id),
            station_id
        ) b
          on upper(a.css_id) = b.upper_css_id
          and a.station_id = b.station_id
          and a.id <> b.true_id
      );
    SQL

    # Uppercase all user records' CSS IDs.
    execute "update users set css_id = upper(css_id);"
  end
  # rubocop:enable Metrics/MethodLength

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
