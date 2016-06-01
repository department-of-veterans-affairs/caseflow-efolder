source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.5.2'
# Use sqlite3 as the database for Active Record
gem 'sqlite3', platforms: :ruby
gem 'activerecord-jdbcsqlite3-adapter', platforms: :jruby

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'

# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby
gem 'therubyrhino', platforms: :jruby

# Style
gem 'us_web_design_standards', git: 'https://github.com/harrisj/us_web_design_standards_gem.git', branch: 'rails-assets-fixes'
# TODO: We can remove the git path when this pull request is merged in:
#       https://github.com/18F/us_web_design_standards_gem/pull/7/commits

# SSOI
gem 'omniauth-saml-va', git: 'https://github.com/department-of-veterans-affairs/omniauth-saml-va', branch: 'paultag/css'

gem 'bourbon'
gem 'neat'

gem 'puma'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'sidekiq'

gem 'rubyzip'

gem 'connect_vbms', path: './vendor/gems/connect_vbms'
gem 'bgs', git: "https://github.com/department-of-veterans-affairs/ruby-bgs.git", :branch => 'master'
#gem 'connect_vbms', git: 'https://github.com/department-of-veterans-affairs/connect_vbms.git'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug'

  gem 'brakeman', '3.1.5'
  gem 'bundler-audit'

  gem 'pry'

  gem 'rubocop', '~> 0.36.0', require: false
  gem 'scss_lint', require: false
end

group :test do
  gem 'rspec'
  gem 'rspec-rails'
  #gem 'guard-rspec'
  gem 'capybara', '2.6.2'
  gem 'sniffybara', git: 'https://github.com/department-of-veterans-affairs/sniffybara.git'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  #gem 'web-console', '~> 2.0'

  # For windows
  gem 'tzinfo-data'
end

