# Editor README
---
This is the names and taxonomy Editor for the NSL project, widely known as the "NSL Editor".

This document was last updated in March 2026.

## Background

Greg Whitbread migrated an early Australian Plant Names Index (APNI) from a Pick system into an Oracle database in the 1990s and wrote an Oracle Forms front-end.

This was called the APNI System and was used for Australian Plant Nomenclature and Taxonomy by the joint ANBG/CSIRO project.

In 2010 (or thereabouts) and project started which was founded on the success of Greg's still-running APNI System, but aimed to refine the APNI database design and broaden its application beyond Plants to other Nomenclatural Codes.  The new system was the National Species List - NSL in short.

Greg Whitbread was the intellectual leader for the NSL project and had some hand in choosing the team and the technology for the project.  He chose Ruby on Rails (RoR) as the technology and Postgresql as the database. In 2010 RoR was a relatively new but popular framework for building database-backed web apps, and Postgresql was emerging as a strong open source contender in the RDBMS space previously dominated by commercial products like Oracle.

After some setbacks and staff changes, several decisions were made in or around 2013 and 2014, one of which was to use separate databases for each body of names - so, for instance, APNI data was migrated to a separate NSL database, and the plan was for other data (e.g. Moss, Lichen, Algae, Fungi) each to be in their own separate databases, while sharing a common NSL schema.

The first version of the Editor was targetted at APNI data, but again the goal was for instances of the running Editor to be pointed at other NSL databases as they became available.


## Brief History of Versions

Greg Clarke (GC) was hired as a contract developer specifically to design and build an NSL Editor in Rails, and he worked on the Editor from its inception until 2026.

The Editor was released in 2014 running on Rails 4.x and has been in use in the NSL project since then, starting with APNI data, but now also including Algae, Fungi, Lichen, and Moss in separate databases.

The current Editor git repo does not go back to that original version - it goes back several years to when the Editor was upgraded to Rails 6.  That was unfortunate becaues we lost continuity of the change history, but at the time it made the upgrade the Rails 6 feasible/possible.

The Editor was upgraded to Rails 7 in 2023, then to Rails 8 in 2025.

### Note on repositories
The original Rails 4.x app repository is now archived on Github.  One unfortunate side-effect of starting a new repo for the Rails 6 upgrade was that contributions by others ended up in my (Greg Clarke's) name in the version 6.x app.  You also lose the history and context of the changes.  Neither of those results was my intention at a very frustrating time when I started with a clean Rails 6 application and copied in the controller, model, and view files, etc.

While most of the app going back to its origins in 2012 is down to me (GC), most of the "tree" ops were coded by others, especially Peter McNeil -- look at the archived v4.x app to find out more.


## Some definitions and technical notes
NSL is the National Species List project of the Integrated Biodiversity Information Systems (IBIS) team based at the Australian National Botanic Gardens (ANBG) site.

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

We moved to SimpleAD when we migrated to AWS in 2022.

We have also added some authorisations into database tables:
  * Batch loaders can authorise batch reviewers on specific batches and that is recorded in the core database
  * The Flora of Australia project introduced Products and Product Roles with authorisations for profile and tree editing coming from these records in the database
  * We added a Users table (in 2023?) to let known users be authorised - this started in a small way for batch reviewers, but now every user who logs in gets a record added to the users table unless one already exists (great idea Gerda!)
  * The plan going forward is to move all authorisations from SimpleAD into database tables.


## Database creation

The NSL database structure was built and seeded as a separate task, away from the Editor, and is maintained separately from the Editor, so you'll find no migration or seed files.

## Database initialization

As above, this app doesn't carry the information necessary to create the database, which is created and maintained separately from this app.

## How to run the test suite

We have used simple minitest Rails testing with fixtures for most of the life of this app.  We mock calls out to the Services app for testing.

Recently Gerda added Rspec tests, so we have a mixture of minitest and rspec tests.

### Grab the schema

We use a `structure.sql` file extracted from a copy of an active NSL database.  When the database structure changes we need to refresh `structure.sql`.

This is more complicated in our case because the NSL project uses various extensions and complex views in the NSL databases.  Over time, we've had problems loading the structure.sql into a test database using standard Rails commands.

Starting out, you typically take steps like this:

   1. Set up access to an active NSL database or a local copy of such a database with the latest schema changes.
   2. Run `rake db:schema:dump` on command line, and based on our config, you will get a structure.sql file

The problems typically come when using that structure.sql file to setup a new test database.

We have used two approaches to solve this problem.

   1. Hand edit the structure.sql file to remove views and whatever else that
    a) we don't use in the Editor
    b) cause an error in setup

   2. Run a custom task (db:clean_up_structure_sql) to edit the structure.sql file to achieve the same result.  The command is:

      dropdb ned_test; createdb -O nsl ned_test; bundle exec rake db:schema:dump; bundle exec rake db:clean_up_structure_sql; RAILS_ENV=test bin/rails db:setup


You should then be able to run minitests and rspecs in the usual way.


## Services and Mapper

The Editor requires NSL Services and Mapper for some advanced features to work.

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
#### Running the editor along with the other services using the docker-apps
1. Get the `docker-apps` codes in the bitbucket repo
2. Follow the docker-apps set up instructions
3. If you're running the db from another docker stack:
   3.1 Turn off the `nsl_app_dev` container since we are going to use the editor from docker-apps. Leave the `nsl_db_dev` container running
   ```bash
      docker-compose -f docker-compose.dev.yml stop nsl_app_dev
   ```
   3.2 Grab the latest dump file from test
   ```bash
      # Download the latest dump from test
      # Copy it into the docker container of the db and restore inside the container (e.g container name is nsl_db_dev)
      # e.g
      # docker cp /path/to/the/downloaded/my_dump_file.sql nsl_db_dev:/tmp/
      # docker exec -e PGPASSWORD=password nsl_db_dev pg_restore -U myuser -h nsl_db_dev -d nsl_editor_development /tmp/my_dump_file.sql
      #
      docker cp /path/to/the/downloaded/<dumpfile.sql> <docker_container_name_of_the_db>:/tmp/
      docker exec -e PGPASSWORD=<password> nsl_db_dev pg_restore -U <user> -h <host> -d <db_name> /tmp/<dump_file>
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

There was an original (old) search engine - you can see that in the models - under search, you'll find some models (e.g. on_name) with their own base.rb, predicate.rb, etc.

During the first decade of the Editor I created a generalized search engine, the "new" engine, and entities enrolled in that search engine have just a field_abbrev.rb and a field_rule.rb file.

Below are the files of the search engine, containing old and new - the new engine is concentrated under on_model:

√  Thu 26 9:09 ruby 3.4.8  ~/anbg/rails/nedruby/app/models
% tree search
search
├── author
│   ├── field_abbrev.rb
│   └── field_rule.rb
├── base.rb
├── bulk_processing_log
│   ├── field_abbrev.rb
│   └── field_rule.rb
├── empty_executed_query.rb
├── empty_parsed_request.rb
├── empty.rb
├── error.rb
├── help
│   └── page_mappings.rb
├── loader
│   ├── batch
│   │   ├── field_abbrev.rb
│   │   ├── field_rule.rb
│   │   ├── review
│   │   │   ├── field_abbrev.rb
│   │   │   ├── field_rule.rb
│   │   │   └── period
│   │   │       ├── field_abbrev.rb
│   │   │       └── field_rule.rb
│   │   ├── reviewer
│   │   │   ├── field_abbrev.rb
│   │   │   └── field_rule.rb
│   │   └── stack
│   │       ├── field_abbrev.rb
│   │       └── field_rule.rb
│   └── name
│       ├── field_abbrev.rb
│       ├── field_rule.rb
│       └── rewrite_results_showing_extras.rb
├── next_criterion.rb
├── on_instance
│   ├── base.rb
│   ├── count_query.rb
│   ├── field_abbrev.rb
│   ├── field_rule.rb
│   ├── list_query.rb
│   ├── predicate.rb
│   └── where_clauses.rb
├── on_model
│   ├── base.rb
│   ├── count_query.rb
│   ├── list_query.rb
│   ├── predicate.rb
│   └── where_clauses.rb
├── on_name
│   ├── base.rb
│   ├── count_query.rb
│   ├── field_abbrev.rb
│   ├── field_rule.rb
│   ├── list_query.rb
│   ├── predicate.rb
│   ├── where_clauses.rb
│   ├── with_instances_to_copy.rb
│   └── with_instances.rb
├── org
│   ├── field_abbrev.rb
│   └── field_rule.rb
├── parsed_defined_query.rb
├── parsed_request.rb
├── reference
│   ├── defined_query
│   │   ├── base.rb
│   │   ├── count.rb
│   │   ├── list.rb
│   │   ├── predicate.rb
│   │   └── where_clauses.rb
│   ├── defined_query.rb
│   ├── field_abbrev.rb
│   └── field_rule.rb
├── target.rb
└── user
    ├── field_abbrev.rb
    └── field_rule.rb





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


Most Search has been migrated to the new search engine, with these known exceptions:

References - this still has some "defined queries", which were an early idea for custom searches that ran out of steam
Instances  - not migrated to the new search engine
Name - not migrated to the new search engine
Activity Search - has it's own little engine  (Note: this was originally called "audit" search and you'll find it under Audit in the source code.)
Batch tab Search - a small custom engine

