# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym 'RESTful'
# end

# For more info on zeitwerk and autoloading constants
# https://guides.rubyonrails.org/v6.0.2.1/autoloading_and_reloading_constants.html
# (Also check out `config/initializers/zeitwerk.rb`)
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "BGS"
  inflect.acronym "VBMS"
  inflect.acronym "VVA"
end