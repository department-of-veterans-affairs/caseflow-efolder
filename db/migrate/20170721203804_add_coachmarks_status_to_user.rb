class AddCoachmarksStatusToUser < ActiveRecord::Migration
  def change
    add_column :users, :coachmarks_status, :integer, default: 0
  end
end
