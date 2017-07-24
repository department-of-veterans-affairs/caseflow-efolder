class AddVvaCoachmarksViewCountToUser < ActiveRecord::Migration
  def change
    # vva_coachmarks_view_count records the number of times the user has
    # been shown the coachmarks on initial page load. The value can be 0, 1, or 
    # 2, because after 2, the app stops showing coachmarks. If the user clicks
    # "See what's new!", the coachmarks display, but it's not counted in this column. 
    add_column :users, :vva_coachmarks_view_count, :integer, default: 0
  end
end
