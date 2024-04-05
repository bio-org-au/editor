# Editor README
---
This is the names and taxonomy Editor for the NSL project, sometimes called the "NSL Editor". 

## Brief History of Versions

The Editor was released in 2014 running on Rails 4.x and has been in use in the NSL project since then.

This repository does not go back to that original version - it goes back several years to when the Editor was upgraded to Rails 6.

The Editor was upgraded to Rails 7 in 2023.

### Note on repositories
The original Rails 4.x app repository is now archived.  One unfortunate side-effect of starting a new repo for the Rails 6 upgrade was that contributions by others ended up in my (Greg Clarke's) name in the version 6.x app.  You also lose the history and context of the changes.  Neither of those results was my intention and it seemed like a good idea at a very frustrating time, so start with a clean Rails 6 application and copy in the controller, model, and view files, etc.  While most of the app going back to its origins in 2012 is down to me (GC), most of the "tree" ops were coded by others, especially Peter McNeil -- look at the archived v4.x app to find out more.


## NSL
NSL is the National Species List project of the IBIS team based at the Australian National Botanic Gardens (ANBG) site.  

The Editor works with and relies on services provides by the NSL Services and the NSL Mapper apps.  

It uses the NSL data structures.


## Current Ruby version: 3.x

Currently running on Ruby 3.x

### Previously on JRuby
Note, this app was originally developed, tested, and deployed in JRuby - from 2013-2022, running finally on `jruby-9.3.2.0` in 2022.

In that year we moved to a C-Ruby deployment on AWS, so it is now developed, tested, and deployed in C-Ruby.

## Postgresql database

Developed against a Postgresql database, designed to by run as a low-privilege CRUD user.

## Authentication

User authentication/authorisation is via LDAP/Active Directory - originall LDAP, more recently AD.

## Database creation

The NSL database structure was built and seeded as a separate task, away from the Editor, so you'll find no migration or seed files.

## Database initialization

As above, this app doesn't carry the information necessary to create the database, which is created and maintained separately from this app.

## How to run the test suite

Presumes: you have a copy of an NSL database
Preparation - run:  rails db:schema:dump to produce db/structure.sql
Preparation - edit: db/structure.sql to remove min/max constraints on nsl_global_seq

Create a test database, load the sql structure, run tests: 
    createdb -O nsldev ned_test
    RAILS_ENV=test rake db:structure:load 
    bundle exec rails:test

## Services and Mapper

Requires NSL Services and Mapper for some advanced features to work.

### Services (job queues, cache servers, search engines, etc.)

This app is constrained to call out to the Services app for "services" such as name construction, taxonomy operations and certain deletes.

The Services app in turn relies on a Mapper app.

## External Configuration files

Database config file is expected at `~/.nsl/editor-database.yml`
Configuration file is expected at `~/.nsl/development/editor-r7-config.rb` (for development).

## Deployment instructions

Set up an NSL database - structure and seed data for look-up tables (seed data files not in this repo).
Set up editor-database.yml and editor-r7-config.rb
The editor-r7-config.rb must identify a active LDAP authentication/authorisation service.
The editor-database.yml user can be the table-owner in development, but should be a less-powerful user in non-devt deploys.
You'll need a user registered in that LDAP, ideally with appropriate group memberships
cd [app home]
rails s

## Release notes

There is a longish trail of release notes in annuallly rolled-over yaml files held in
`config/history/` and visible from the help menu in the Editor.

Contact ibissupport at anbg for more information.


