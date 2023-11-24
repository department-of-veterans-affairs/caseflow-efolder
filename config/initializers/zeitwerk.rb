
# Zeitwerk has specific requirements for auto/eager loading. See below links for more details
# https://guides.rubyonrails.org/classic_to_zeitwerk_howto.html
# https://github.com/fxn/zeitwerk

# To sumarize Zeitwerk requires several conditions be met when attempting to auto/eager load
#    - The top level namespace must reflect the auto/eager-loadpath / filename. The auto/eager-load
#      path will be different from the relative path. See https://github.com/fxn/zeitwerk#file-structure
#    - Zeitwerk expects 1 constant per file, anything not under that constant won't be loaded
#    - Acronyms aren't implicit. You can use them but you'll need to tell zeitwerk. (More details below)
#    - The constant name and file name MUST match, or zeitwerk needs to be told otherwise.
#      So file_name.rb should be `module or class FileName`. 
#    - Namespaces need to be unique. Depending on the auto/eager-load path, files with the same
#      name but located in different directories can cause issues. To avoid this try and name files uniquely as well.


# In order to use acronyms you have two methods. Only the latter will allow you to tell zeitwerk to look for
# a different consant than the original filename though. 
#
# To change an acronym globally you need to go to `config/initialzers/inflections.rb`. Though it should
# be noted that adding already existing acronyms this way may cause more problems than solutions. For this
# the second solution is recomended. 
#
# Alternatively within this file you can add an inflector as well, though in this case for a specific file.
# The ""s to the left of the arrow is the file_name, and the ""s to right is what Zeitwerk should be
# looking for when it runs across said file_name. Note how no file paths are specified, hence the need
# to ensure files have individual names so solutions like this don't affect every file with that name. 

# When problem solving uninitialized constant errors, the usual cause is the namespace not matching
# up with what zeitwerk excpects to find. There are many ways to solve this, if the above doesn't work
# Try adding / removing namespaces through the direct modification of code, or by modifying the 
# directory structure itself. 

# Use the command and test below to ensure zeitwerk compliance.
# bin/rails zeitwerk:check
# A rspec test has been added, check CI output for details

Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "bgs_errors" => "BGS",
    "poa_mapper" => "POAMapper",
  )
end

# Example of removing a directory from being autoloaded
# ActiveSupport::Dependencies.
#   autoload_paths.
#   delete("#{Rails.root}/app/)
  