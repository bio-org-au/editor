# Editor README
---
This is the names and taxonomy Editor for the NSL project. It was released in 2014 running on Rails 4.x, was recreated in Rails 6 after several years, then upgraded to Rails 7 in 2023.

NSL is the National Species List project of the IBIS team based at the Australian National Botanic Gardens (ANBG) site.  

The Editor works with and relies on services provides by the Services and Mapper apps.  It uses the NSL data structures.


## Current Ruby version: 3.2.2

Currently running on Ruby 3.2.2.

Note, this app was originally developed, tested, and deployed in JRuby - from 2013-2022, running finally on `jruby-9.3.2.0` in 2022.  In that year we moved to a c-ruby deployment on AWS, so it is now deveoped, tested, and deployed in Ruby.  You may find remnants of JRuby in the app but hopefully less-and-less as time goes on.

## System dependencies

Developed against a Postgresql database, version 9 and 10, designed to by run as a low-privilege CRUD user.

Requires Services and Mapper for some features to work.

User authentication/authorisation is via LDAP/Active Directory - originall LDAP, more recently AD.

Currently Rails 7.0.  There was an original Rails 4.* application for many years, now archived, but for the Rails 6.0 upgrade I started with a clean app and copied slabs of code across - one unfortunate side-effect was that contributions by others ended up in my name in the version 6.x app.  That wasn't my intention - while most of the app is down to me (GC), most of the "tree" ops were coded by others -- look at the archived v4.x app to find out more.

## Configuration

Database config file is expected at `~/.nsl/editor-database.yml`
Configuration file is expected at `~/.nsl/development/editor-r7-config.rb` (for development).
Sample config file below.

## Database creation

This app doesn't carry the information necessary to create the database, which is created and maintained separately from this app.

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

## Services (job queues, cache servers, search engines, etc.)

This app is constrained to call out to the Services app for "services" such as taxonomy operations and deletes.

The Services app in turn relies on a Mapper app.


## Deployment instructions

Set up an NSL database - structure and seed data for look-up tables (seed data not in this repo).
Set up editor-database.yml and editor-r7-config.rb
cd [app home]
rails s


Contact ibissupport at anbg for more information.

## Release notes

There is a longish trail of release notes in annuallly rolled-over yaml files held in
`config/history/` and visible from the help menu in the Editor.


## Running

To run in development run `rails s` from the command line in your project directory

