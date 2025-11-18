# Editor README
---
This is the names and taxonomy Editor for the NSL project, sometimes called the "NSL Editor".

This document was last updated on 3 November 2025.

## Brief History of Versions

The Editor was released in 2014 running on Rails 4.x and has been in use in the NSL project since then.

This repository does not go back to that original version - it goes back several years to when the Editor was upgraded to Rails 6.

The Editor was upgraded to Rails 7 in 2023, then to Rails 8 in 2025.

### Note on repositories
The original Rails 4.x app repository is now archived on github.  One unfortunate side-effect of starting a new repo for the Rails 6 upgrade was that contributions by others ended up in my (Greg Clarke's) name in the version 6.x app.  You also lose the history and context of the changes.  Neither of those results was my intention at a very frustrating time when I started with a clean Rails 6 application and copied in the controller, model, and view files, etc.  

While most of the app going back to its origins in 2012 is down to me (GC), most of the "tree" ops were coded by others, especially Peter McNeil -- look at the archived v4.x app to find out more.


## NSL
NSL is the National Species List project of the IBIS team based at the Australian National Botanic Gardens (ANBG) site.

The Editor works with and relies on services provides by the NSL Services and the NSL Mapper apps.

It uses the NSL data structures.


## Current Ruby version: 3.x

Currently running on Ruby 3.x

### Previously on JRuby
Note, this app was originally developed, tested, and deployed in JRuby - from 2013-2022, running finally on `jruby-9.3.2.0` in 2022.

In that year we moved to a C-Ruby deployment on AWS, so it is now developed, tested, and deployed in C-Ruby. Thanks to Daniel Cox from Blue Crystal for sorting that out!

## Postgresql database

Developed against a Postgresql database, designed to be run as a low-privilege CRUD user.

## Authentication/Authorisation

User authentication/authorisation was originallhy entirely via LDAP.

We moved to SimpleAD on AWS in 2022.

We have also added some authorisations into database tables:
  * Batch loaders can authorise batch reviewers on specific batches and that is recorded in the core database
  * The Flora of Australia project introduced Products and Product Roles with authorisations for profile and tree editing coming from these records in the database
  * We added a Users table (in 2023?) to let known users be authorised - this started in a small way for batch reviewers, but now every user who logs in gets a record added to the users table unless one already exists (great idea Gerda!)
  * The plan going forward is to move all authorisations from SimpleAD into database tables.


## Database creation

The NSL database structure was built and seeded as a separate task, away from the Editor, so you'll find no migration or seed files.

## Database initialization

As above, this app doesn't carry the information necessary to create the database, which is created and maintained separately from this app.

## How to run the test suite

We have used simple minitest Rails testing with fixtures for most of the life of this app.  We mock calls out to the Services app for testing.

Recently Gerda added rspecs.

### Grab the schema

We use a `structure.sql` file extracted from a copy of an active NSL database.  When the database structure changes we need to refresh `structure.sql`.

   1. Set up access to an active NSL database or a local copy of such a database with the latest schema changes.
   2. Run `SCHEMA_FORMAT='sql' rake db:schema:dump` on command line
   3. Edit the resulting `structure.sql` file - modify the `create sequence public.nsl_global_seq ...` statement by
      a) setting the `start with` value to 1, and
      b) removing the `minvalue` and `maxvalue` constraints.

      This sequence is set in very particular ways in the various active NSL databases, but we need it simple, predictable, and unconstrained for our test fixtures.

### Run tests

Create a test database, load the sql structure, run tests - e.g.:

      createdb -O nsldev ned_test
      RAILS_ENV=test rake db:schema:load
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

## Development

Current stack:
- Ruby version 3.4.5
- Rails version 8.0.0
- Postgresql version 15.7

Pre-requisites:
- Acquire the following:
    - vpn config
    - database.yml and editor-config.rb files

### 🐳 Setup with Docker

There are a couple of files/folders you need to acquire from the team before you can start running the docker containers:

All of these live in the root directory of the `editor`

- `.env` (see the template.env and acquire the necessary information from the team)
- `.nsl` folder containing the database.yml and editor-config.rb
- `.pgpass` file with the postgress password

Run
```bash
# build the containers
docker-compose -f docker-compose.dev.yml build

# run the postgres db container
# create the necessary database
# and restore the db dump from this container
# e.g psql -U user -d database
docker-compose -f docker-compose.dev.yml run db_dev bash

# run the containers
docker-compose -f docker-compose.dev.yml up -d
```
### 💪🏻 Non-Docker
Pre-requisite
- Postgres database installed on your machine
- Config files in the right directory. [External Configuration Files](https://github.com/bio-org-au/editor?tab=readme-ov-file#external-configuration-files)

#### Intall Ruby with the following:
- [Using RVM](https://rvm.io/rvm/install) or with
- [the asdf version manager](https://github.com/asdf-vm/asdf-ruby)


Run
```bash
# Create database and restore data
psql -U user -d databasename
pgrestore -U user -d databasename path/to/the/source.dmp

# install the gems
bundle install

# run the server
rails s
```
### Annotaterb
Since we don't conventionally use db migrations, the annotaterb gem won't be triggered once a db schema is changed.

Manually update the annotations in the models, factories, and fixtures excluding test files:
```bash
bundle exec annotaterb models --exclude tests,spec
```

## Release notes

There is a longish trail of release notes in annuallly rolled-over yaml files held in
`config/history/` and visible from the help menu in the Editor.


Contact ibissupport at anbg for more information.


## Search Mechanism

The Search mechanism is very important - editing NSL data involves a lot of searching.

The Editor Search mechanism is built to allow:

  * one page for all searches and results
  * one field for all search entry
  * use of defined custom search directives

The Search engine behind all this is a little bit complicated, but it has the following benefits:

   * multiple records of different types can be returned and displayed in a search result
   * it is trivial to add a new search - simply figure out the required SQL and map it to a new search directive
       * no GUI work is required
       * no extra search entry fields are required

   * registering and enabling search on an extra table is possible with a few hours or a solid day's work

The diagram below is a start to documenting where to look in the code for parts of these mechanisms.




                               Query in the Editor





                     ┌─────────────────┐
                     │                 │                     app/controllers/search_controller.rb #search
                     │ Search Request  │
                     │                 │                     app/controllers/search_controller.rb #run_local_search
                     └────────┬────────┘
                              │
                     ┌────────▼────────┐
                     │                 │
                     │  Search Model   │───┐                 @search = ::Search::Base.new(params)
                     │                 │   │
                     └────────┬────────┘   │
                   ┌──────────┘            │                 Search::Base#run_query
                   ▼                       ▼
          ┌─────────────────┐     ┌─────────────────┐
          │      Old        │     │      New        │
          │  Search Engine  │     │  Search Engine  │        Search::OnModel::Base
          │                 │     │                 │
          └─────────────────┘     └─────────────────┘
                                           │
                                           │
                                           ▼
                                  ┌─────────────────┐
                                  │                 │
                                  │  Parse Request  │        app/models/search/parsed_request.rb
                                  │                 │
                                  └─────────────────┘
                                           │
                                           │
                                           ▼
                                  ┌─────────────────┐
                                  │    Convert      │        e.g.
                                  │   Directives    │        app/models/search/loader/name/field_rule.rb
                                  │     to SQL      │
                                  └─────────────────┘
                                           │
                                           │
                                           ▼
                                  ┌─────────────────┐
                                  │                 │
                                  │   Execute SQL   │       app/models/search/base.rb # run_query
                                  │                 │
                                  └─────────────────┘
                                           │
                                           ▼
                            ┌────────────────────────────┐
                            │       Display Results      │
                            │ ┌────────────────────────┐ │
                            │ │                        │ │
                            │ │   Summarise Results    │ │ app/views/search/search_result_summary
                            │ │                        │ │
                            │ └────────────────────────┘ │
                            │ ┌────────────────────────┐ │
                            │ │                        │ │
                            │ │  Apply record-type to  │ │ app/views/application/search_results/standard/_results.html.erb
                            │ │       display          │ │
                            │ └────────────────────────┘ │
                            └────────────────────────────┘

