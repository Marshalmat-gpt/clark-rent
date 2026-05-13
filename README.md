# Clark Rent — API Backend

[![CI](https://github.com/Marshalmat-gpt/clark-rent/actions/workflows/ci.yml/badge.svg)](https://github.com/Marshalmat-gpt/clark-rent/actions/workflows/ci.yml)
[![Ruby](https://img.shields.io/badge/ruby-3.2.2-red)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/rails-7.2-cc0000)](https://rubyonrails.org/)
[![License](https://img.shields.io/badge/license-proprietary-blue)](#)

Rails API pour la plateforme Clark Rent : gestion locative intelligente avec agent conversationnel IA (Claude).

## Stack

- **Ruby on Rails 7.2** (API mode), Ruby 3.2.2, Bundler 4
- **PostgreSQL 16** + **Redis 7** (cache + Sidekiq)
- **Sidekiq 7** + **sidekiq-cron 2** for async + scheduled jobs
- **Anthropic Claude** via the `anthropic` gem (tool-use loop)
- **AWS S3** for documents (presigned URLs via `aws-sdk-s3`)
- **SendGrid** SMTP for transactional email, **Twilio** for SMS
- **JWT** auth (`HS256`, 24h TTL) — `Authorization: Bearer <token>`
- **Rack::Attack** rate limiting on `/agent/chat` + `/sessions`
- **Sentry** + **Lograge** for error + structured logging
- **Bullet** (dev/test) for N+1 detection

## Quick start

```bash
git clone git@github.com:Marshalmat-gpt/clark-rent.git
cd clark-rent
cp .env.example .env          # fill the variables documented below

# With Docker Compose (recommended) — boots Postgres + Redis + web + worker
docker compose up --build

# Without Docker
bundle install
bundle exec rails db:create db:migrate db:seed
bundle exec rails server
```

Health check : `curl http://localhost:3000/health` should return `{ "status": "ok", "db": true, "redis": …, "sidekiq": … }`.

## Project layout

```
app/
  controllers/api/v1/         # REST endpoints
  controllers/api/v1/agent/   # Chat + agent-side resources
  models/                     # ActiveRecord (User, Property, Room,
                              # Lease, LeaseApplication, RentPayment, Ticket)
  services/clark_agent/       # ContextBuilder, IrlCalculator, ReceiptPdf,
                              # Orchestrator, ToolRegistry, ToolExecutor
  jobs/                       # SendNotificationJob, MonthlyRentPaymentsJob,
                              # TicketSlaEscalationJob,
                              # LeaseIrlAnniversaryReminderJob
  mailers/                    # ApplicationMailer + per-domain mailers
config/
  schedule.yml                # sidekiq-cron entries (3 jobs)
docs/
  API.md                      # human-readable API reference
  openapi.yaml                # OpenAPI 3.1 spec for codegen / Postman
```

## API

See `docs/API.md` and `docs/openapi.yaml`. Endpoint surface:

- `/health`
- `/sessions` (login)
- `/users`, `/properties`, `/rooms`
- `/leases`, `/lease_applications`, `/rent_payments`
- `/agent/chat`, `/agent/context`, `/agent/tickets`, `/agent/receipts`, …

Every index endpoint is paginated (`?page=`, `?per_page=` ≤100) and exposes `X-Total-Count` / `X-Page` / `X-Per-Page` / `X-Total-Pages` headers.

## Scheduled jobs

Wired via `sidekiq-cron` and `config/schedule.yml`:

| Job | Cron (UTC) | Purpose |
|---|---|---|
| `GenerateMonthlyRentPaymentsJob` | `0 4 1 * *` | Pre-generate 3 months of pending `RentPayment` rows for every active lease |
| `TicketSlaEscalationJob` | `0 */6 * * *` | Notify landlords of urgent tickets open > 48h |
| `LeaseIrlAnniversaryReminderJob` | `0 7 * * *` | Email landlords on lease anniversaries to prompt IRL revision |

Inspect the queue + retries at `/admin/sidekiq` (basic auth via `SIDEKIQ_WEB_USERNAME` / `SIDEKIQ_WEB_PASSWORD`).

## Env vars

See `.env.example` for the full list. Critical ones:

| Var | Notes |
|---|---|
| `DATABASE_URL` | Postgres |
| `REDIS_URL` | Redis (Sidekiq + cache) |
| `SECRET_KEY_BASE` | Rails |
| `JWT_SECRET` | Session tokens |
| `ANTHROPIC_API_KEY` | Agent IA |
| `AWS_*` (`ACCESS_KEY_ID`, `SECRET_ACCESS_KEY`, `REGION`, `BUCKET`) | S3 |
| `SENDGRID_API_KEY`, `MAIL_FROM`, `MAIL_DOMAIN`, `APP_HOST` | Email |
| `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM` | SMS |
| `SIDEKIQ_WEB_USERNAME`, `SIDEKIQ_WEB_PASSWORD` | `/admin/sidekiq` |
| `SENTRY_DSN` | Error tracking |

## CI gates

GitHub Actions runs four jobs in parallel on every push and PR:

| Job | What |
|---|---|
| `RuboCop` | style |
| `RSpec` | full test suite (PostgreSQL + Redis services) |
| `Brakeman` | static security analysis (`--no-exit-on-warn`) |
| `Bundler-audit` | vulnerability scan against `ruby-advisory-db` |

## Branches

| Branche | Rôle |
|---|---|
| `main` | Production |
| `develop` | Intégration |
| `feature/*` | Features en cours |
| `release/vX.Y` | Préparation release |

## Roadmap

- ✅ v0.1 — CRUD Users / Properties / Rooms / Auth JWT
- ✅ v0.2 — Leases, Lease Applications
- ✅ v0.3 — Agent IA (tool-use loop, 10 tools, tickets, IRL, quittances PDF)
- ✅ v0.4 — Rent payments, mailers, SMS, scheduled jobs, ops dashboards
- 🚧 v0.5 — Document signing, admin endpoints
