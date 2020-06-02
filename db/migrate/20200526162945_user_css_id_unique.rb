class UserCssIdUnique < Efolder::Migration
  def up
    safety_assured { execute "create unique index index_users_unique_css_id on users using btree (upper(css_id))" }
    add_safe_index :users, [:last_login_at]
  end

  def down
    safety_assured { execute "drop index index_users_unique_css_id" }
    remove_index :users, [:last_login_at]
  end
end
