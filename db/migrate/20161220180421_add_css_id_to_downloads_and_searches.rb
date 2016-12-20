class AddCssIdToDownloadsAndSearches < ActiveRecord::Migration
  def change
    add_column :searches, :css_id, :string
    add_column :downloads, :css_id, :string

    (Search.all + Download.all).each do |record|
      record.update(css_id: record.user_id)
    end
  end
end
