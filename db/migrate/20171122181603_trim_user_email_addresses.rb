class TrimUserEmailAddresses < ActiveRecord::Migration
  def up
    execute "update users set email = trim(email);"
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
