
# Zeitwerk has specific requirements for auto/eager loading. See below links for more details
# https://guides.rubyonrails.org/classic_to_zeitwerk_howto.html
# https://github.com/fxn/zeitwerk

# To sumarize Zeitwerk requires several conditions be met when attempting to auto/eager load
#    - The top level namespace must reflect the auto/eager-loadpath / filename. The auto/eager-load
#      path will be different from the relative path. See https://github.com/fxn/zeitwerk#file-structure
#    - Zeitwerk expects 1 constant per file, anything not under that constant won't be loaded
#    - Acronyms aren't implicit. You can use them but you'll need to tell zeitwerk. (More details below)
#    - The constant name and file name MUST match, or zeitwerk needs to be told otherwise.
#      So file_name.rb should be `module or class FileName` not `FileNames``. 
#    - Namespaces need to be unique. Depending on the auto/eager-load path, files with the same
#      name but located in different directories can cause issues. This also applies to any Gems you have have installed.
#
#
# Use the command and test below to ensure zeitwerk compliance.
# A rspec test has been added for this, you can also check your CI output for details
# bin/rails zeitwerk:check

# For more info add Rails.autoloaders.log! to your application.rb file 
# before running the zeitwerk:check for a breakdown of what zeitwerk is doing.

Rails.autoloaders.each do |autoloader|
  # "file_name" => Expected Module or Class name. 
  autoloader.inflector.inflect(
    "bgs" => "BGS",
    "bgs_service" => "BGSService",
    "poa_mapper" => "POAMapper",
    "vbms_service" => "VBMSService",
    "vva_service" => "VVAService"
  )
end