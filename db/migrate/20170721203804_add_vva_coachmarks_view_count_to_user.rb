class AddVvaCoachmarksViewCountToUser < ActiveRecord::Migration
  def change
    add_column :users, :vva_coachmarks_view_count, :integer, default: 0
  end
end
