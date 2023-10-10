
# Zeitwerk has specific requirements in order to auto/eager load.
# The first is we have to convert the files that don't convert to camelcase on their own.
# Easiest way is to use config/initializers/inflections.rb which tells rails to see what you add there
# as an acronym and camelcase accordingly. So adding "VVA" changes the expected result from 
# "Vva" to "VVA" for all files

# The second way can be seen below. This allows for more control but you have to add each individual
# file needed to the list. Ex: POAExample will not be found as zeitwerk stil expects PoaExample

# Next, Zeitwerk expects a constant, based off file name, to be defined within said file.
# The constant and it's hierarchy is based off the autoloaded paths. So while Zeitwerk expects
# "BGSErrors" to be defined at the top level of "bgs_errors.rb", some files might require
# an additional layer. Ex: "EXNamespace::EXConstant"
# Use the command below to ensure zeitwerk compliance.
#
# For example: A constant called BGSErrors needs to be defined AND it must be defined
# at the top level of bgs_errors.rb as the path to there is:
# app/exceptions/bgs_errors.rb 

# Testing Zeitwerk
# Use bin/rails zeitwerk:check
# Or run ~~~RSPEC ZEITWERK TEST HERE~~~ 

Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "poa_mapper" => "POAMapper",
  )
end