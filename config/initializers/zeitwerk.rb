
# https://guides.rubyonrails.org/classic_to_zeitwerk_howto.html
# Zeitwerk has specific requirements in order to auto/eager load.

# First anything you wish to autoload MUST be in it's own file OR under the top level namespace.
# Ex: If you wanted to autoload "bgs_errors.rb", a constant named BGSErrors needs to be the 
# top level of said file. Or you need to set an inflector (as done below) to tell Rails what to look for instead.
# Rails automatically autoloads everything under that top level constant.
# See https://guides.rubyonrails.org/classic_to_zeitwerk_howto.html#one-file-one-constant-at-the-same-top-level

# Second we have to convert the files that don't autoload on their own. Usually this is due to camelcase errors.
# One issue you'll run into is files with acronyms not being found, as rails doesn't know to uppercase the entire acronym.
# To correct this use config/initializers/inflections.rb for acronyms. 
# So adding "VVA" changes the expected result from "Vva" to "VVA" for all files

# The other issue you can run into is the namespace not matching the autopath / expected constant. 
# This requires a bit more work to correct depending on what rails is asking for. One way to solve this
# is to use the autoloader.inflector below. This will allow you to rails what name it should expect.
# Ex: For "bgs_errors.rb" rails expects BGSErrors as the constant. Below we add
# "bgs_errors" => "BGS" allowing zeitwerk to autoload this file correctly.
#
# However sometimes what rails expects isn't as direct as the example above. Take shell_command.rb
# for example. When you run the check command rails expects Tasks::Support::ShellCommand. The inflector
# below won't allow "::" so you'll have to either create that hirearchy based off what rails requires, or
# you need to change or remove the directory/file, or remove that file from being autoloaded all together.
# Though doing so obviously comes with it's own downsides. 
#
# Use the command and test below to ensure zeitwerk compliance.
# bin/rails zeitwerk:check
# ~~~RSPEC ZEITWERK TEST HERE~~~ 

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
  