class AddCoachmarksStatusToUser < ActiveRecord::Migration
  def change
    add_column :users, :coachmarks_status, :integer
  end
end
