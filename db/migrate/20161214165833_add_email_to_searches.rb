class AddEmailToSearches < ActiveRecord::Migration
  def change
    add_column :searches, :email, :string, limit: 191
  end
end
