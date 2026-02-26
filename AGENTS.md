# AGENTS.md - NSL Editor (nedruby)

Guidance for AI coding agents working in this Ruby on Rails codebase.

## Project Overview

The **NSL Editor** is a Rails 8 application for editing botanical names and taxonomy data (Australian National Botanic Gardens). Uses Ruby 3.4.5, Rails 8.0, PostgreSQL 15.7.

## Build/Test/Lint Commands

### Tests (Minitest and RSpec)

```bash
# All Minitest
bundle exec rails test

# Single Minitest file / specific line
bundle exec rails test test/models/author_test.rb
bundle exec rails test test/models/author_test.rb:25

# All RSpec
bundle exec rspec

# Single RSpec file / specific line
bundle exec rspec spec/models/name_spec.rb
bundle exec rspec spec/models/name_spec.rb:10
```

### Linting

```bash
bin/rubocop                # RuboCop linter
bin/brakeman               # Security scanner
bundle exec annotaterb models --exclude tests,spec  # Update model annotations
```

### Development

```bash
bundle install       # Install dependencies
bin/dev              # Start dev server
bin/setup            # Full setup
bin/rails db:prepare # Prepare database
```

## Code Style Guidelines

### File Header (Required)

All Ruby files must include frozen string literal and Apache 2.0 license:

```ruby
# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
```

### Formatting Rules

| Rule | Guideline |
|------|-----------|
| Strings | Double quotes: `"string"` not `'string'` |
| Trailing commas | Multiline hashes: yes. Arrays: no |
| Line/method length | No limits (disabled) |
| `unless` | Never with `&&`/`||`. Use `if !condition` |

### Strict Rules (Will Fail CI)

- **No `binding.pry` or `debugger`** statements
- **No `puts` debugging** (Rails/Output enforced)
- Use `find_each` over `each` for AR collections
- Use `uniq.pluck` not `pluck.uniq`

### Model Conventions

```ruby
class MyModel < ApplicationRecord
  self.table_name = "my_table"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"  # Shared sequence

  include NameScopable  # Use concerns for shared behavior
end
```

- `ApplicationRecord` auto-strips whitespace via `strip_attributes`
- Schema annotations managed by `annotaterb` gem

### Service Object Pattern

```ruby
class MyService < BaseService
  def initialize(params, options = nil)
    @params = params
    @options = options
    @logger = Rails.logger
  end

  def execute
    # Must override - raises NotImplementedError by default
  end
end

# Usage
MyService.call(params, options)
MyService.new_call_transaction(params)  # With rollback on errors
```

### Test Conventions

**Minitest** (`test/`): fixtures, FactoryBot, WebMock
**RSpec** (`spec/`): shoulda-matchers, DatabaseCleaner, FactoryBot

```ruby
FactoryBot.define do
  factory :author do
    lock_version { 1 }
    sequence(:abbrev) { |n| "Sample Abbrev #{n}" }
    association :namespace
  end
end
```

## Project Structure

```
app/
  controllers/     # CanCanCan authorization
  models/          # ActiveRecord models
    concerns/      # Shared model modules
  services/        # BaseService pattern
db/
  structure.sql    # Schema (externally managed, no migrations)
spec/              # RSpec tests
test/              # Minitest tests
  factories/       # FactoryBot factories
  fixtures/        # Test fixtures
```

## Important Notes

- **No migrations** - Schema managed externally via `structure.sql`
- **PostgreSQL** with shared sequence (`nsl_global_seq`)
- **Auth**: LDAP/SimpleAD, CanCanCan authorization (`current_user`, `current_ability`)
- **External configs**: `~/.nsl/editor-database.yml`, `~/.nsl/development/editor-r7-config.rb`
- **CI configs**: `.nsl-test-configs/`
- **CI/CD**: Both Minitest and RSpec must pass; RuboCop and Brakeman enforced
