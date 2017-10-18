source ENV['GEM_SERVER_URL'] || 'https://rubygems.org'

gem "caseflow", git: "https://github.com/department-of-veterans-affairs/caseflow-commons", ref: "706ba7bde215f53d96365e3dba217f9a98781f4e"

gem "moment_timezone-rails"

# Use sqlite3 as the database for Active Record
gem 'sqlite3', platforms: [:ruby,:mswin,:mingw, :mswin, :x64_mingw]

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.7.1'

gem 'pg', platforms: :ruby
gem 'activerecord-jdbcpostgresql-adapter', platforms: :jruby

gem 'aws-sdk', '~> 2'

gem 'prometheus-client', "~> 0.6"

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'

# Explicitly adding USWDS gem until it's published and we can
# include it via commons
gem "uswds-rails", git: "https://github.com/18F/uswds-rails-gem.git"

# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby
gem 'therubyrhino', platforms: :jruby

# Error reporting to Sentry
gem "sentry-raven"

# SSOI
gem 'omniauth-saml-va', git: 'https://github.com/department-of-veterans-affairs/omniauth-saml-va', branch: 'paultag/css'

gem 'puma'

gem 'rack-cors', :require => 'rack/cors'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'redis-rails'

gem 'sidekiq'
gem "sidekiq-cron", "~> 0.4.0"

gem 'rubyzip'

# use to_b method to convert string to boolean
gem 'wannabe_bool'

gem 'zaru'

gem 'active_model_serializers'

gem 'redis-namespace'

gem 'request_store'

gem 'connect_vbms', git: "https://github.com/department-of-veterans-affairs/connect_vbms.git", ref: "87d0cab4bb5a87e70d6e2dab81e1da17fc512571"
gem 'connect_vva', git: "https://github.com/department-of-veterans-affairs/connect_vva.git", ref: "f1389dab28158076d856f614ed85af0cf167522f"
gem 'bgs', git: "https://github.com/department-of-veterans-affairs/ruby-bgs.git", :branch => 'master'
#gem 'connect_vbms', git: 'https://github.com/department-of-veterans-affairs/connect_vbms.git'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :production, :staging do
  gem 'rails_stdout_logging'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug'

  gem 'brakeman', '3.1.5'
  gem 'bundler-audit'

  gem 'pry'

  gem 'rubocop', '~> 0.36.0', require: false
  gem 'scss_lint', require: false
  gem "dotenv-rails"
end

group :test do
  gem 'timecop'
  gem 'rspec'
  gem 'rspec-rails'
  #gem 'guard-rspec'
  gem 'simplecov'
  gem 'capybara', '2.6.2'
  gem 'sniffybara', git: 'https://github.com/department-of-veterans-affairs/sniffybara.git', branch: 'axe'
  # to save and open specific page in capybara tests
  gem 'launchy'
  gem 'database_cleaner'
  gem 'test_after_commit'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  #gem 'web-console', '~> 2.0'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: :ruby
  gem 'rb-readline'


  # For windows
  gem 'tzinfo-data'
end
