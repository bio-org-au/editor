# Editor README
---
This a names-and-usages-editor (the "Editor") first released in 2014 within a suite of applications targetting the National Species List (NSL) database structure developed by the IBIS team based at ANBG.  It presupposes, and in same cases depends on, a `Services` app and a `Mapper` app.


## Ruby version: 2.6.10

Note, this app was originally developed, tested, and deployed in JRuby - from 2013-2022, running finally on `jruby-9.3.2.0` in 2022.  In that year we moved to a c-ruby deployment on AWS, so it is now deveoped, tested, and deployed in Ruby.  You may find remnants of JRuby in the app but hopefully not as time goes on.

## System dependencies

Developed against a Postgresql database, version 9 and 10, designed to by run as a low-privilege CRUD user.

Currently Rails 6.1.  There was an original Rails 4.* application for many years, now archived, but for the Rails 6.0 upgrade I started with a clean app and copied slabs of code across - one unfortunate side-effect was that contributions by others ended up in my name in the version 6.x app.  That wasn't my intention - while most of the app is down to me (GC), most of the "tree" ops were coded by others -- look at the archived v4.x app to find out more.

## Configuration

Database config file is expected at `~/.nsl/editor-database.yml`
Configuration file is expected at `~/.nsl/development/editor-r6-config.rb` (for development).
Sample config file below.

## Database creation

This app doesn't carry the information necessary to create the database, which is created and maintained separately from this app.

## Database initialization

As above, this app doesn't carry the information necessary to create the database, which is created and maintained separately from this app.

## How to run the test suite

Create a test database, load the sql structure, run tests: 
    createdb -O nsldev ned_test
    RAILS_ENV=test rake db:structure:load 
    bundle exec rails:test

## Services (job queues, cache servers, search engines, etc.)

This app is constrained to call out to the Services, and Mapper apps for "services" like taxonomy operations and deletes.

The application could likely do with a proper job queue, as could Services, for handling long-running tasks. 


## Deployment instructions

Get an NSL database.
Set up editor-database.yml and editor-r6-config.rb
rails s

## Release notes

There is a longish trail of release notes in annual yaml files held in
`config/history/` and visible from the help menu in the Editor.

## Example local development editor-config.rb

    % cat editor-r6-config.rb

    #host
    external_host = 'http://localhost:9093'
    external_services_host = "#{external_host}/nsl/services"
    internal_services_host = 'http://localhost:9093/nsl/services'

    internal_mapper_host = 'http://localhost:9094'
    external_mapper_host = 'http://localhost:9094'

    #environment
    Rails.configuration.config_file_tag = 'apni development'
    Rails.configuration.action_controller.relative_url_root = "/nsl/editor"
    Rails.configuration.environment = 'development'
    Rails.configuration.session_key_tag = 'in-dev-only'
    Rails.configuration.draft_instances = 'true'
    Rails.configuration.orchids_aware = true
    Rails.configuration.allow_orchid_tree_operations = true
    Rails.configuration.batch_loader_aware = true
    Rails.configuration.profile_edit_aware = true

    #Services
    Rails.configuration.services_clientside_root_url = "#{external_services_host}/"
    Rails.configuration.services = "#{internal_services_host}/"
    Rails.configuration.name_services = "#{internal_services_host}/rest/name/apni/"
    Rails.configuration.reference_services = "#{internal_services_host}/rest/reference/apni/"

    # - used to create external facing links to the services
    Rails.configuration.nsl_links = "#{external_services_host}/"

    # - API key for the services
    Rails.configuration.api_key = 'some-api-key-goes-here'

    #mapper
    Rails.configuration.x.mapper_api.version = 2
    Rails.configuration.x.mapper_api.url = "#{internal_mapper_host}/api/"
    Rails.configuration.x.mapper_api.username = 'some-username'
    Rails.configuration.x.mapper_api.password = 'this-isnt-the-password'
    Rails.configuration.x.mapper_external.url = "#{external_mapper_host}/"

    #ldap
    Rails.configuration.ldap_admin_username = "not-real-data"
    Rails.configuration.ldap_admin_password = "this-isnt-the-password"
    Rails.configuration.ldap_base = "not-real-data"
    Rails.configuration.ldap_host = "not-real-data"
    Rails.configuration.ldap_port = "not-real-data"
    Rails.configuration.ldap_users = "not-real-data"
    Rails.configuration.ldap_generic_users = "not-real-data"
    Rails.configuration.ldap_groups = "not-real-data"
    Rails.configuration.ldap_via_active_directory = boolean_goes_here
    Rails.configuration.group_filter_regex = 'not-real-data"

    #email
    Rails.configuration.action_mailer.delivery_method = nil
    Rails.configuration.action_mailer.perform_deliveries = false
    Rails.configuration.action_mailer.raise_delivery_errors = false
    Rails.configuration.action_mailer.smtp_settings = {}

    #feedback
    Rails.configuration.offer_feedback_link = false
    Rails.configuration.feedback_script = '<script></script>'

    Rails.configuration.path_to_broadcast_file = '/path/to/broadcast.txt'


## Fragment of local development editor-database.yml


% cat ~/.nsl/editor-database.yml

    default: &default
      adapter: postgresql
      encoding: unicode

    development:
      <<: *default
      host: localhost
      database: nsl_dev
      username: nsl
      pool: 10

## Running

To run in development run `rails s` from the command line in your project directory

