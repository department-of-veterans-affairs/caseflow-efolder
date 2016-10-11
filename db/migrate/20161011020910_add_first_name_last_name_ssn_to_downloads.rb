class AddFirstNameLastNameSsnToDownloads < ActiveRecord::Migration
  def up
    # we could be more clever here by renaming a name column
    # instead of adding two columns, but this seems fine.
    add_column :downloads, :veteran_last_name, :string
    add_column :downloads, :veteran_first_name, :string
    add_column :downloads, :veteran_last_four_ssn, :string

    Download.find_each do |download|
      if download.veteran_name
        # This isn't going to be exactly right in all cases--
        # if one's first name were "Carly Rae" and last name
        # "Jepsen", for instance, we would split on the wrong
        # space. However, historical Download rows are kept
        # for record-keeping, so it's probably acceptable.
        first, last = download.veteran_name.split(' ', 2)
        download.update(veteran_first_name: first, veteran_last_name: last)
      end
    end

    remove_column :downloads, :veteran_name
  end
  def down
    add_column :downloads, :veteran_name, :string

    Download.find_each do |download|
      full_name = "#{download.veteran_first_name} #{download.veteran_last_name}"
      download.update(veteran_name: full_name)
    end

    remove_column :downloads, :veteran_last_four_ssn
    remove_column :downloads, :veteran_first_name
    remove_column :downloads, :veteran_last_name
  end
end
