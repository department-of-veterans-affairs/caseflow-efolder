class CreateUsers < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.string :css_id, null: false
      t.string :station_id, null: false
      t.string :email
      t.timestamps null: false
    end

    add_index :users, [:css_id, :station_id]
    add_belongs_to :searches, :user, index: true, foreign_key: true
    add_belongs_to :downloads, :user, index: true, foreign_key: true

    (Search.all + Download.all).each do |record|
      next unless (record.css_id && record.user_station_id)

      user = User.find_or_create_by(css_id: record.css_id, station_id: record.user_station_id)

      email = record.is_a?(Download) ? record.searches.last.try(:email) : record.email
      user.update(email: email) if email

      record.update(user: user)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
