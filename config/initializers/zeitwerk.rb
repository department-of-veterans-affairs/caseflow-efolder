
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
#      name but located in different directories can cause issues. To avoid this try and name files uniquely as well.

# Use the command and test below to ensure zeitwerk compliance.
# bin/rails zeitwerk:check
# Alternatively an rspec test has been added, check CI output for details

Rails.autoloaders.each do |autoloader|
  # A collapse statement will remove the need for a namespace based on the direcotry given.
  # Tasks::Support::ModuleOrClassNme becomes ModuleOrClassName with the below statements.
  autoloader.collapse("app/jobs/middleware")
  autoloader.collapse("lib/tasks")
  autoloader.collapse("lib/tasks/support")
  
  # "file_name" => Expected Module or Class name. 
  autoloader.inflector.inflect(
    "bgs_errors" => "BGS",
    "bgs_service" => "BGSService",
    "poa_mapper" => "POAMapper",
    "vbms_service" => "VBMSService",
    "vva_service" => "VVAService"
  )
end