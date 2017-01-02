class CreateUsers < ActiveRecord::Migration
  def change
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
      next unless record.css_id

      user = User.find_or_create_by(css_id: record.css_id, station_id: record.user_station_id)
      user.update(email: record.email) if record.email
      record.update(user: user)
    end
  end
end
