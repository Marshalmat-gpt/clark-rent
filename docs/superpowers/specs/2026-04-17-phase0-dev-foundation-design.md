# Phase 0 — Dev Foundation Design Spec

**Project:** Clark Rent  
**Date:** 2026-04-17  
**Status:** Approved  
**Scope:** Development infrastructure — Rails scaffold, Docker Compose, CI, code quality, Railway deployment

---

## Context

Clark Rent is a Rails 7.1 API for intelligent rental management with a conversational AI agent (Anthropic Claude). As of this spec, the repo contains only 5 skeleton files: `Gemfile`, `.gitignore`, `.env.example`, `config/routes.rb`, `README.md`. No application code exists yet.

This Phase 0 establishes the complete development foundation before any domain code is written. All subsequent phases (v0.1–v0.3) depend on this infrastructure being in place.

**Chosen approach:** Full Dev Loop (Option B) — Docker Compose + GitHub Actions CI + Railway deployment config + full RSpec/RuboCop setup.

---

## Section 1: Repository Structure

The following structure is scaffolded in Phase 0. Directories marked `# Phase N` are created as empty stubs now and filled in the corresponding phase.

```
clark-rent/
├── .github/
│   └── workflows/
│       └── ci.yml                    # RuboCop + RSpec on every push/PR
├── app/
│   ├── controllers/
│   │   └── api/v1/                   # REST endpoints — Phase 1+
│   ├── models/                       # ActiveRecord models — Phase 1+
│   ├── services/
│   │   └── clark_agent/              # AI orchestrator stub — Phase 3
│   ├── jobs/                         # Sidekiq async jobs — Phase 4
│   ├── mailers/                      # SendGrid mailers — Phase 4
│   └── serializers/                  # active_model_serializers — Phase 1+
├── config/
│   ├── routes.rb                     # Already exists
│   ├── database.yml                  # Uses DATABASE_URL env var
│   ├── puma.rb                       # Puma config
│   ├── sidekiq.yml                   # Queue priorities
│   └── initializers/
│       ├── cors.rb                   # rack-cors config
│       └── sidekiq.rb                # Redis connection
├── db/
│   ├── migrate/                      # Migrations — Phase 1+
│   └── schema.rb
├── spec/
│   ├── rails_helper.rb               # DatabaseCleaner, FactoryBot, shoulda-matchers
│   ├── spec_helper.rb                # Core RSpec config
│   ├── support/
│   │   ├── factory_bot.rb
│   │   ├── database_cleaner.rb
│   │   └── request_helpers.rb        # sign_in_as(user) JWT helper
│   └── factories/                    # One file per model — Phase 1+
├── docker-compose.yml                # web + postgres + redis + sidekiq
├── Dockerfile                        # Multi-stage build
├── .dockerignore
├── bin/
│   └── docker-entrypoint             # Waits for DB, runs db:prepare, starts server
├── Procfile                          # Railway: web + worker
├── .rubocop.yml                      # Code style rules
└── .env.example                      # Updated with all required vars
```

**Key decisions:**
- `app/services/clark_agent/` stubbed now, implemented in Phase 3
- `spec/` fully wired so tests can be added milestone by milestone without setup debt
- No `app/` domain code in Phase 0 — models/controllers come in Phase 1

---

## Section 2: Docker Compose

Four services, all wired together:

```
┌─────────────┐     ┌──────────────┐
│  web         │────▶│  postgres    │
│  Rails :3000 │     │  :5432       │
└──────┬──────┘     └──────────────┘
       │
       ▼
┌─────────────┐     ┌──────────────┐
│  sidekiq    │────▶│  redis       │
│  (worker)   │     │  :6379       │
└─────────────┘     └──────────────┘
```

### Services

| Service | Image | Purpose |
|---|---|---|
| `postgres` | `postgres:16` | Primary database, data persisted via `pg_data` named volume |
| `redis` | `redis:7-alpine` | Sidekiq job queue backend |
| `web` | Built from `Dockerfile` | Rails API, code mounted as volume for hot-reload |
| `sidekiq` | Same as `web` | Runs `bundle exec sidekiq`, shares codebase with `web` |

### Dockerfile (multi-stage)

- **Stage 1 `builder`**: installs gems, sets up build dependencies
- **Stage 2 `production`**: copies only runtime artifacts, runs as non-root user for security

### `bin/docker-entrypoint`

Startup sequence:
1. Wait for Postgres to accept connections (retry loop)
2. Run `rails db:prepare` (creates DB if missing, runs pending migrations)
3. Start the server

No manual `db:create` or `db:migrate` needed after `docker compose up`.

### Dev workflow

```bash
docker compose up                        # start everything
docker compose run web rails c           # Rails console
docker compose run web rspec             # run tests
docker compose run web rails db:migrate  # run migrations
```

---

## Section 3: GitHub Actions CI

Two jobs run **in parallel** on every push and pull request:

```
push / PR
    │
    ├──▶ rubocop      (~1 min)
    │     └── bundle exec rubocop
    │
    └──▶ rspec        (~3–5 min)
          ├── services: postgres:16, redis:7
          ├── bundle install (cached by Gemfile.lock hash)
          ├── db:create + db:migrate
          └── bundle exec rspec
```

### Key design decisions

- **Bundler cache**: gems cached by `Gemfile.lock` SHA — saves ~30s on warm runs
- **Real services**: Postgres and Redis run as service containers, no mocking
- **Fail-fast separation**: RuboCop and RSpec fail independently — style errors don't hide test failures
- **No deploy step in CI**: Railway auto-deploys from `main` via GitHub integration (configured in Railway dashboard)
- **Branch protection** (manual setup): both jobs must pass before merging to `main` or `develop`

### Triggers

- Push to any branch
- Pull request targeting `main` or `develop`

---

## Section 4: Code Quality

### RuboCop (`.rubocop.yml`)

Inherits from `rubocop-rails` with Rails API-optimised defaults:

| Cop | Setting | Reason |
|---|---|---|
| `Layout/LineLength` | Max: 120 | Rails API code is verbose |
| `Style/Documentation` | Disabled | No class/module doc comments required |
| `Style/FrozenStringLiteralComment` | Disabled | Too noisy at this stage |
| All Rails cops | Enabled | N+1 guards, scope best practices, etc. |

### RSpec

```
spec/
├── rails_helper.rb         # DatabaseCleaner, FactoryBot, shoulda-matchers config
├── spec_helper.rb          # RSpec core config: random order, progress formatter
├── support/
│   ├── factory_bot.rb      # FactoryBot.find_definitions
│   ├── database_cleaner.rb # transaction for unit specs, truncation for request specs
│   └── request_helpers.rb  # sign_in_as(user) — injects valid JWT Authorization header
└── factories/              # Added per-model in Phase 1+
```

**DatabaseCleaner strategy:**
- Unit/model specs → **transactions** (fast, rolled back after each example)
- Request specs → **truncation** (avoids cross-connection state leaks with Sidekiq)

**`sign_in_as(user)` helper:** generates a valid JWT and sets the `Authorization: Bearer <token>` header on the current request spec session. Every Phase 1+ request spec uses this — no repetition.

**Coverage enforcement:** not added in Phase 0. A minimum threshold (e.g. 90%) is introduced in Phase 1 once real code exists.

---

## Section 5: Railway Deployment Config

### `Procfile`

```
web:    bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
```

### `config/sidekiq.yml`

```yaml
:concurrency: 5
:queues:
  - [critical, 3]
  - [default, 2]
  - [low, 1]
```

### `config/database.yml`

Uses `DATABASE_URL` directly — no hardcoded credentials:

```yaml
default: &default
  adapter: postgresql
  url: <%= ENV['DATABASE_URL'] %>
  pool: <%= ENV.fetch('RAILS_MAX_THREADS') { 5 } %>

development:
  <<: *default
  database: clark_development

test:
  <<: *default
  database: clark_test

production:
  <<: *default
```

### Environment variables

| Variable | Phase | Used by |
|---|---|---|
| `DATABASE_URL` | 0 | Rails / ActiveRecord |
| `REDIS_URL` | 0 | Sidekiq |
| `SECRET_KEY_BASE` | 0 | Rails |
| `JWT_SECRET` | 1 | Auth |
| `ANTHROPIC_API_KEY` | 3 | AI Agent |
| `AWS_ACCESS_KEY_ID` | 4 | ActiveStorage / S3 |
| `AWS_SECRET_ACCESS_KEY` | 4 | ActiveStorage / S3 |
| `AWS_REGION` | 4 | ActiveStorage / S3 |
| `AWS_BUCKET` | 4 | ActiveStorage / S3 |
| `SENDGRID_API_KEY` | 4 | Mailers |
| `TWILIO_ACCOUNT_SID` | 4 | SMS |
| `TWILIO_AUTH_TOKEN` | 4 | SMS |

**No `railway.toml` needed** — Railway auto-detects Rails from `Gemfile` + `Procfile`. Only the Railway dashboard requires manual setup: link the GitHub repo and set the env vars above for Phase 0 (`DATABASE_URL`, `REDIS_URL`, `SECRET_KEY_BASE`).

---

## Out of Scope (this phase)

- Domain models, controllers, serializers → Phase 1
- Leases, applications → Phase 2
- AI agent services → Phase 3
- Mailers, jobs, S3 → Phase 4
- Pundit, Rack::Attack, DB indexes → Phase 5

---

## Success Criteria

Phase 0 is complete when:

- [ ] `docker compose up` starts all 4 services without errors
- [ ] `docker compose run web rspec` runs (0 examples, 0 failures)
- [ ] `docker compose run web rubocop` passes with 0 offenses
- [ ] GitHub Actions CI passes on a test PR
- [ ] `GET /health` returns `200 ok` from the running container
- [ ] Railway deployment succeeds on push to `main`
