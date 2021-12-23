source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.8'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.4'
# Use jdbcpostgresql as the database for Active Record
gem 'activerecord-jdbcpostgresql-adapter'
# Use Puma as the app server
gem 'puma', '>= 5.5.1'
# Use SCSS for stylesheets
# gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
# gem 'sassc-rails'
gem 'webpacker', '~> 5.x'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

gem 'listen', '>= 3.0.5', '< 3.2'
group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  # gem 'sass-rails', '>= 6'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  # gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
end

group :test do
    gem "minitest"
    gem "minitest-rails"
    gem "minitest-reporters"
    gem "launchy"
    gem "mocha", "~> 1.1.0"
    # NoMethodError: assert_template has been extracted to a gem. To continue using it, add:
    gem 'rails-controller-testing'
end

group :development, :test do
  gem "pry-rails"
  gem "pry-rescue"
  gem "webmock"
  # gem "schema_plus"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Added
gem 'warbler', '~> 2.0.5'
gem "strip_attributes"
gem "cancancan"
gem "active_type"
# gem "bootstrap-sass"
gem "font-awesome-rails"
gem "net-ldap"
gem "composite_primary_keys"
gem "sucker_punch"
gem "pg_search"

gem "nokogiri", ">= 1.12.5"
gem "rest-client"
gem "kramdown", ">= 2.3.0"
gem "exception_notification"
gem "websocket-extensions", ">= 0.1.5"
gem "rack", ">= 2.2.3"
gem "simple_calendar", "~> 2.0"

gem "addressable", ">= 2.8.0"

gem 'simplecov', require: false, group: :test
