# Phase 0 — Dev Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish the complete development infrastructure for Clark Rent so every subsequent phase has a working local dev loop, CI quality gate, and Railway deployment pipeline from day one.

**Architecture:** Rails 7.1 API-only app, fully containerised with Docker Compose (web + postgres + redis + sidekiq), tested with RSpec + FactoryBot, linted with RuboCop, deployed to Railway via Procfile. GitHub Actions runs RuboCop and RSpec in parallel on every push.

**Tech Stack:** Ruby 3.2.2 · Rails 7.1 · PostgreSQL 16 · Redis 7 · Sidekiq 7.2 · RSpec 6.1 · RuboCop Rails · Docker Compose · GitHub Actions · Railway

**Spec:** `docs/superpowers/specs/2026-04-17-phase0-dev-foundation-design.md`

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `Gemfile` | Modify | Add `database_cleaner-active_record`, `shoulda-matchers` |
| `config/boot.rb` | Create | Bundler setup |
| `config/application.rb` | Create | Rails app module, API mode, Sidekiq adapter |
| `config/environment.rb` | Create | Boot initializer |
| `config.ru` | Create | Rack entry point |
| `Rakefile` | Create | Rake task loader |
| `config/environments/development.rb` | Create | Dev-specific Rails config |
| `config/environments/test.rb` | Create | Test-specific Rails config |
| `config/environments/production.rb` | Create | Production Rails config |
| `config/database.yml` | Create | DATABASE_URL-based PG config |
| `config/puma.rb` | Create | Puma threads + workers |
| `config/sidekiq.yml` | Create | Queue priorities |
| `config/initializers/cors.rb` | Create | rack-cors middleware |
| `config/initializers/sidekiq.rb` | Create | Redis connection |
| `app/controllers/application_controller.rb` | Create | ActionController::API base |
| `app/controllers/api/v1/base_controller.rb` | Create | API namespace base + error handlers |
| `app/services/clark_agent/.keep` | Create | Stub for Phase 3 |
| `app/jobs/.keep` | Create | Stub for Phase 4 |
| `app/mailers/.keep` | Create | Stub for Phase 4 |
| `app/serializers/.keep` | Create | Stub for Phase 1 |
| `Dockerfile` | Create | Multi-stage Ruby image |
| `.dockerignore` | Create | Exclude logs, tmp, git |
| `bin/docker-entrypoint` | Create | Wait for DB + db:prepare + exec |
| `docker-compose.yml` | Create | web + postgres + redis + sidekiq |
| `Procfile` | Create | Railway: web + worker |
| `.rubocop.yml` | Create | Rubocop-rails + API defaults |
| `spec/spec_helper.rb` | Create | RSpec core config, random order |
| `spec/rails_helper.rb` | Create | Rails + FactoryBot + support loader |
| `spec/support/factory_bot.rb` | Create | FactoryBot syntax methods |
| `spec/support/database_cleaner.rb` | Create | Transaction / truncation strategy |
| `spec/support/request_helpers.rb` | Create | `auth_headers(user)` JWT helper |
| `.github/workflows/ci.yml` | Create | Parallel RuboCop + RSpec jobs |

---

## Setup (run once before Task 1)

```bash
git clone https://github.com/Marshalmat-gpt/clark-rent.git
cd clark-rent
git checkout -b feature/phase0-dev-foundation
```

---

## Task 1: Update Gemfile

**Files:**
- Modify: `Gemfile`

- [ ] **Step 1: Add missing test gems to Gemfile**

Open `Gemfile` and replace the `group :development, :test` block with:

```ruby
group :development, :test do
  gem 'pry-rails'
  gem 'rspec-rails', '~> 6.1'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'dotenv-rails'
  gem 'database_cleaner-active_record', '~> 2.1'
  gem 'shoulda-matchers', '~> 5.3'
end
```

- [ ] **Step 2: Generate Gemfile.lock**

```bash
docker run --rm -v "$PWD":/app -w /app ruby:3.2.2-slim \
  bash -c "apt-get update -qq && apt-get install -y build-essential libpq-dev git && bundle install"
```

Expected: `Bundle complete!` with lock file written to `Gemfile.lock`.

- [ ] **Step 3: Commit**

```bash
git add Gemfile Gemfile.lock
git commit -m "chore: add database_cleaner and shoulda-matchers to Gemfile"
```

---

## Task 2: Rails Core Scaffold

**Files:**
- Create: `config/boot.rb`
- Create: `config/application.rb`
- Create: `config/environment.rb`
- Create: `config.ru`
- Create: `Rakefile`

- [ ] **Step 1: Create `config/boot.rb`**

```ruby
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
require 'bundler/setup'
```

- [ ] **Step 2: Create `config/application.rb`**

```ruby
require_relative 'boot'
require 'rails/all'

Bundler.require(*Rails.groups)

module ClarkRent
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true
    config.time_zone = 'Paris'
    config.i18n.default_locale = :fr
    config.active_job.queue_adapter = :sidekiq
  end
end
```

- [ ] **Step 3: Create `config/environment.rb`**

```ruby
require_relative 'application'
Rails.application.initialize!
```

- [ ] **Step 4: Create `config.ru`**

```ruby
# frozen_string_literal: true

require_relative 'config/environment'
run Rails.application
Rails.application.load_server
```

- [ ] **Step 5: Create `Rakefile`**

```ruby
require_relative 'config/application'
Rails.application.load_tasks
```

- [ ] **Step 6: Commit**

```bash
git add config/boot.rb config/application.rb config/environment.rb config.ru Rakefile
git commit -m "chore: add Rails core scaffold files"
```

---

## Task 3: Rails Environment Configs

**Files:**
- Create: `config/environments/development.rb`
- Create: `config/environments/test.rb`
- Create: `config/environments/production.rb`

- [ ] **Step 1: Create `config/environments/development.rb`**

```ruby
Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true
  config.cache_store = :null_store
  config.active_support.deprecation = :log
  config.active_record.verbose_query_logs = true
  config.active_record.migration_error = :page_load
end
```

- [ ] **Step 2: Create `config/environments/test.rb`**

```ruby
Rails.application.configure do
  config.cache_classes = true
  config.eager_load = false
  config.public_file_server.enabled = true
  config.consider_all_requests_local = true
  config.cache_store = :null_store
  config.active_support.deprecation = :stderr
  config.active_support.discard_errors_in_after_callbacks = false
  config.active_record.maintain_test_schema = true
end
```

- [ ] **Step 3: Create `config/environments/production.rb`**

```ruby
Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.log_level = :info
  config.log_tags = [:request_id]
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
  config.force_ssl = true
end
```

- [ ] **Step 4: Commit**

```bash
git add config/environments/
git commit -m "chore: add Rails environment configs"
```

---

## Task 4: Database Config

**Files:**
- Create: `config/database.yml`

- [ ] **Step 1: Create `config/database.yml`**

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  url: <%= ENV.fetch('DATABASE_URL', "postgresql://clark:clark@localhost/clark_#{Rails.env}") %>
  pool: <%= ENV.fetch('RAILS_MAX_THREADS', 5) %>

development:
  <<: *default
  database: clark_development

test:
  <<: *default
  database: clark_test

production:
  <<: *default
```

- [ ] **Step 2: Commit**

```bash
git add config/database.yml
git commit -m "chore: add database config using DATABASE_URL"
```

---

## Task 5: Puma and Sidekiq Config

**Files:**
- Create: `config/puma.rb`
- Create: `config/sidekiq.yml`

- [ ] **Step 1: Create `config/puma.rb`**

```ruby
max_threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
min_threads_count = ENV.fetch('RAILS_MIN_THREADS') { max_threads_count }
threads min_threads_count, max_threads_count

worker_timeout 3600 if ENV.fetch('RAILS_ENV', 'development') == 'development'

port ENV.fetch('PORT', 3000)
environment ENV.fetch('RAILS_ENV', 'development')

pidfile ENV.fetch('PIDFILE', 'tmp/pids/server.pid')

if ENV.fetch('RAILS_ENV', 'development') == 'production'
  workers ENV.fetch('WEB_CONCURRENCY', 2)
end

preload_app!
plugin :tmp_restart
```

- [ ] **Step 2: Create `config/sidekiq.yml`**

```yaml
:concurrency: 5
:queues:
  - [critical, 3]
  - [default, 2]
  - [low, 1]
```

- [ ] **Step 3: Commit**

```bash
git add config/puma.rb config/sidekiq.yml
git commit -m "chore: add Puma and Sidekiq configs"
```

---

## Task 6: Initializers

**Files:**
- Create: `config/initializers/cors.rb`
- Create: `config/initializers/sidekiq.rb`

- [ ] **Step 1: Create `config/initializers/cors.rb`**

```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('CORS_ORIGINS', '*')
    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             expose: ['Authorization']
  end
end
```

- [ ] **Step 2: Create `config/initializers/sidekiq.rb`**

```ruby
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end
```

- [ ] **Step 3: Commit**

```bash
git add config/initializers/
git commit -m "chore: add CORS and Sidekiq initializers"
```

---

## Task 7: Controllers

**Files:**
- Create: `app/controllers/application_controller.rb`
- Create: `app/controllers/api/v1/base_controller.rb`

- [ ] **Step 1: Create `app/controllers/application_controller.rb`**

```ruby
class ApplicationController < ActionController::API
end
```

- [ ] **Step 2: Create `app/controllers/api/v1/base_controller.rb`**

```ruby
module Api
  module V1
    class BaseController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private

      def not_found
        render json: { error: 'Not found' }, status: :not_found
      end

      def bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end
    end
  end
end
```

- [ ] **Step 3: Commit**

```bash
git add app/controllers/
git commit -m "chore: add ApplicationController and API V1 BaseController"
```

---

## Task 8: Stub Directories

**Files:**
- Create: `app/services/clark_agent/.keep`
- Create: `app/jobs/.keep`
- Create: `app/mailers/.keep`
- Create: `app/serializers/.keep`
- Create: `tmp/pids/.keep`
- Create: `log/.keep`

- [ ] **Step 1: Create stub `.keep` files**

```bash
mkdir -p app/services/clark_agent app/jobs app/mailers app/serializers tmp/pids log
touch app/services/clark_agent/.keep app/jobs/.keep app/mailers/.keep app/serializers/.keep tmp/pids/.keep log/.keep
```

- [ ] **Step 2: Commit**

```bash
git add app/services/ app/jobs/ app/mailers/ app/serializers/ tmp/pids/.keep log/.keep
git commit -m "chore: add stub directories for future phases"
```

---

## Task 9: Dockerfile and .dockerignore

**Files:**
- Create: `Dockerfile`
- Create: `.dockerignore`

- [ ] **Step 1: Create `Dockerfile`**

```dockerfile
# Stage 1: Builder — installs all gems
FROM ruby:3.2.2-slim AS builder

RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev git curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Stage 2: Runtime
FROM ruby:3.2.2-slim

RUN apt-get update -qq && \
    apt-get install -y libpq-dev curl && \
    rm -rf /var/lib/apt/lists/*

# Non-root user for security
RUN useradd -ms /bin/bash clark

WORKDIR /app

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --chown=clark:clark . .

RUN chmod +x bin/docker-entrypoint

USER clark
EXPOSE 3000

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

- [ ] **Step 2: Create `.dockerignore`**

```
.git
.gitignore
log/*
tmp/*
*.swp
*.swo
.DS_Store
coverage/
.env
```

- [ ] **Step 3: Commit**

```bash
git add Dockerfile .dockerignore
git commit -m "chore: add multi-stage Dockerfile and .dockerignore"
```

---

## Task 10: Docker Compose and Entrypoint

**Files:**
- Create: `docker-compose.yml`
- Create: `bin/docker-entrypoint`

- [ ] **Step 1: Create `bin/docker-entrypoint`**

```bash
#!/bin/bash
set -e

# Wait for PostgreSQL to accept connections
echo "Waiting for PostgreSQL..."
until (echo > /dev/tcp/postgres/5432) 2>/dev/null; do
  echo "  PostgreSQL not ready, retrying..."
  sleep 1
done
echo "PostgreSQL is ready."

# Prepare the database (create if missing, run pending migrations)
bundle exec rails db:prepare

exec "$@"
```

Make executable:

```bash
chmod +x bin/docker-entrypoint
```

- [ ] **Step 2: Create `docker-compose.yml`**

```yaml
version: '3.9'

services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: clark
      POSTGRES_PASSWORD: clark
      POSTGRES_DB: clark_development
    volumes:
      - pg_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  web:
    build: .
    command: bundle exec puma -C config/puma.rb
    volumes:
      - .:/app
      - bundle_cache:/usr/local/bundle
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - redis
    environment:
      DATABASE_URL: postgresql://clark:clark@postgres/clark_development
      REDIS_URL: redis://redis:6379/0
      RAILS_ENV: development
      SECRET_KEY_BASE: dev_secret_key_base_change_in_production
      JWT_SECRET: dev_jwt_secret_change_in_production
    env_file:
      - .env

  sidekiq:
    build: .
    command: bundle exec sidekiq -C config/sidekiq.yml
    volumes:
      - .:/app
      - bundle_cache:/usr/local/bundle
    depends_on:
      - postgres
      - redis
    environment:
      DATABASE_URL: postgresql://clark:clark@postgres/clark_development
      REDIS_URL: redis://redis:6379/0
      RAILS_ENV: development
      SECRET_KEY_BASE: dev_secret_key_base_change_in_production
    env_file:
      - .env

volumes:
  pg_data:
  bundle_cache:
```

- [ ] **Step 3: Verify docker-compose config is valid**

```bash
docker compose config --quiet
```

Expected: no output (valid config).

- [ ] **Step 4: Commit**

```bash
git add bin/docker-entrypoint docker-compose.yml
git commit -m "chore: add Docker Compose and entrypoint script"
```

---

## Task 11: Procfile

**Files:**
- Create: `Procfile`

- [ ] **Step 1: Create `Procfile`**

```
web:    bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
```

- [ ] **Step 2: Commit**

```bash
git add Procfile
git commit -m "chore: add Procfile for Railway deployment"
```

---

## Task 12: RuboCop Config

**Files:**
- Create: `.rubocop.yml`

- [ ] **Step 1: Create `.rubocop.yml`**

```yaml
inherit_gem:
  rubocop-rails: rubocop.yml

AllCops:
  NewCops: enable
  SuggestExtensions: false
  TargetRubyVersion: 3.2
  Exclude:
    - 'db/**/*'
    - 'bin/**/*'
    - 'config/**/*'
    - 'vendor/**/*'

Layout/LineLength:
  Max: 120

Style/Documentation:
  Enabled: false

Style/FrozenStringLiteralComment:
  Enabled: false

Rails/FilePath:
  EnforcedStyle: arguments
```

- [ ] **Step 2: Verify RuboCop runs (expect 0 offenses on app/ and spec/)**

```bash
docker compose build web
docker compose run --rm web bundle exec rubocop app/
```

Expected output:

```
Inspecting 2 files
..

2 files inspected, no offenses detected
```

- [ ] **Step 3: Commit**

```bash
git add .rubocop.yml
git commit -m "chore: add RuboCop config with Rails API defaults"
```

---

## Task 13: RSpec Core Setup

**Files:**
- Create: `spec/spec_helper.rb`
- Create: `spec/rails_helper.rb`

- [ ] **Step 1: Create `spec/spec_helper.rb`**

```ruby
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  Kernel.srand config.seed
end
```

- [ ] **Step 2: Create `spec/rails_helper.rb`**

```ruby
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rspec/rails'
require 'factory_bot_rails'

Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join('spec/fixtures')]
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
```

- [ ] **Step 3: Run RSpec to confirm 0 examples, 0 failures**

```bash
docker compose run --rm \
  -e DATABASE_URL=postgresql://clark:clark@postgres/clark_test \
  -e RAILS_ENV=test \
  web bundle exec rails db:create db:migrate
docker compose run --rm \
  -e DATABASE_URL=postgresql://clark:clark@postgres/clark_test \
  -e RAILS_ENV=test \
  web bundle exec rspec
```

Expected:

```
0 examples, 0 failures
```

- [ ] **Step 4: Commit**

```bash
git add spec/spec_helper.rb spec/rails_helper.rb
git commit -m "chore: add RSpec spec_helper and rails_helper"
```

---

## Task 14: RSpec Support Files

**Files:**
- Create: `spec/support/factory_bot.rb`
- Create: `spec/support/database_cleaner.rb`
- Create: `spec/support/request_helpers.rb`

- [ ] **Step 1: Create `spec/support/factory_bot.rb`**

```ruby
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
```

- [ ] **Step 2: Create `spec/support/database_cleaner.rb`**

```ruby
require 'database_cleaner/active_record'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :request) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
```

- [ ] **Step 3: Create `spec/support/request_helpers.rb`**

```ruby
module RequestHelpers
  # Generates Authorization header with a valid JWT for the given user.
  # Usage in request specs:
  #   get '/api/v1/properties', headers: auth_headers(user)
  def auth_headers(user)
    payload = {
      user_id: user.id,
      exp: 24.hours.from_now.to_i
    }
    token = JWT.encode(payload, ENV.fetch('JWT_SECRET', 'test_jwt_secret'), 'HS256')
    { 'Authorization' => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
```

- [ ] **Step 4: Run RSpec to confirm support files load without errors**

```bash
docker compose run --rm \
  -e DATABASE_URL=postgresql://clark:clark@postgres/clark_test \
  -e RAILS_ENV=test \
  -e JWT_SECRET=test_jwt_secret \
  web bundle exec rspec
```

Expected:

```
0 examples, 0 failures
```

- [ ] **Step 5: Commit**

```bash
git add spec/support/
git commit -m "chore: add RSpec support files (FactoryBot, DatabaseCleaner, JWT helper)"
```

---

## Task 15: GitHub Actions CI

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Create `.github/workflows/ci.yml`**

```yaml
name: CI

on:
  push:
    branches: ['**']
  pull_request:
    branches: [main, develop]

jobs:
  rubocop:
    name: RuboCop
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2.2'
          bundler-cache: true
      - name: Run RuboCop
        run: bundle exec rubocop

  rspec:
    name: RSpec
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: clark
          POSTGRES_PASSWORD: clark
          POSTGRES_DB: clark_test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    env:
      DATABASE_URL: postgresql://clark:clark@localhost/clark_test
      REDIS_URL: redis://localhost:6379/0
      RAILS_ENV: test
      SECRET_KEY_BASE: test_secret_key_base_ci
      JWT_SECRET: test_jwt_secret_ci

    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2.2'
          bundler-cache: true
      - name: Set up database
        run: bundle exec rails db:create db:migrate
      - name: Run RSpec
        run: bundle exec rspec
```

- [ ] **Step 2: Commit and push to trigger CI**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add GitHub Actions workflow (RuboCop + RSpec)"
git push origin feature/phase0-dev-foundation
```

- [ ] **Step 3: Open a PR and verify both CI jobs go green**

```bash
gh pr create \
  --title "feat: Phase 0 — Dev Foundation" \
  --body "Sets up full dev infrastructure: Docker Compose, GitHub Actions CI, RuboCop, RSpec, Railway Procfile." \
  --base main
```

Open the PR URL and confirm:
- `RuboCop` job: ✅ passed
- `RSpec` job: ✅ `0 examples, 0 failures`

---

## Task 16: End-to-End Smoke Test

This task verifies all success criteria from the spec before merging.

- [ ] **Step 1: Build and start all services**

```bash
docker compose up --build -d
```

Expected: all 4 containers (`web`, `postgres`, `redis`, `sidekiq`) show status `running`.

```bash
docker compose ps
```

- [ ] **Step 2: Verify /health endpoint**

```bash
curl -s http://localhost:3000/health
```

Expected:

```
ok
```

- [ ] **Step 3: Verify RSpec passes inside container**

```bash
docker compose run --rm \
  -e DATABASE_URL=postgresql://clark:clark@postgres/clark_test \
  -e RAILS_ENV=test \
  -e JWT_SECRET=test_jwt_secret \
  web bundle exec rspec
```

Expected:

```
0 examples, 0 failures
```

- [ ] **Step 4: Verify RuboCop passes inside container**

```bash
docker compose run --rm web bundle exec rubocop
```

Expected:

```
no offenses detected
```

- [ ] **Step 5: Tear down**

```bash
docker compose down
```

- [ ] **Step 6: Merge PR**

Once CI is green and smoke tests pass, merge the PR:

```bash
gh pr merge --squash --delete-branch
```

---

## Phase 0 Complete ✓

All success criteria met:
- `docker compose up` starts all 4 services without errors
- `rspec` runs with `0 examples, 0 failures`
- `rubocop` passes with `0 offenses`
- GitHub Actions CI passes on PR
- `GET /health` returns `200 ok`
- Ready for Railway deployment (set `DATABASE_URL`, `REDIS_URL`, `SECRET_KEY_BASE` in Railway dashboard, link GitHub repo)

**Next:** Phase 1 — v0.1 Core Domain + Auth (Users, Properties, Rooms, JWT sessions)
