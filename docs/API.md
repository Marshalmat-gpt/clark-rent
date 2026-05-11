# Clark Rent — API Reference

REST + JSON API. Base URL: `https://api.clarkrent.com/api/v1` (production) or `http://localhost:3000/api/v1` (dev).

## Conventions

### Authentication

JSON Web Tokens (HS256). Issue a token via `POST /sessions`, then pass it on every authenticated request:

```
Authorization: Bearer <token>
```

Tokens expire after 24h.

### Pagination

All `GET` index endpoints accept:

| Param | Default | Max |
|---|---|---|
| `page` | 1 | — |
| `per_page` | 25 | 100 |

Response headers:

| Header | Meaning |
|---|---|
| `X-Total-Count` | total rows matching the scope |
| `X-Page` | current page |
| `X-Per-Page` | page size applied |
| `X-Total-Pages` | total pages |

### Errors

| Status | Body |
|---|---|
| `400 Bad Request` | `{ "error": "param is missing or the value is empty: …" }` |
| `401 Unauthorized` | `{ "error": "Unauthorized" }` |
| `403 Forbidden` | `{ "error": "Forbidden" }` |
| `404 Not Found` | `{ "error": "Not found" }` |
| `422 Unprocessable Entity` | `{ "errors": ["Email is invalid"] }` |
| `502 Bad Gateway` | `{ "error": "Agent unavailable", "detail": "…" }` (Claude upstream failure) |

### Roles

- `landlord` — owns properties, manages leases / applications / rent payments / tickets on own portfolio.
- `tenant` — applies to rooms, sees own leases, pays rent, opens tickets.

Most index endpoints auto-scope by role.

---

## Health

### `GET /health`

Public. Returns `{ "status": "ok", "db": true, "version": "<sha>" }`.

---

## Auth — `/sessions`

### `POST /sessions`

Body: `{ "email": "…", "password": "…" }`

Returns: `{ "token": "…", "user": { … } }`

### `DELETE /sessions`

Client-side discard token. Server is stateless.

---

## Users — `/users`

| Verb | Path | Role | Notes |
|---|---|---|---|
| `POST` | `/users` | public | sign-up. Body: `{ user: { email, password, first_name, last_name, role } }` |
| `GET` | `/users` | landlord | paginated list of all users |
| `GET` | `/users/:id` | self / landlord | |
| `PATCH` | `/users/:id` | self | update own profile |
| `DELETE` | `/users/:id` | self | |

---

## Properties — `/properties`

| Verb | Path | Notes |
|---|---|---|
| `POST` | `/properties` | landlord creates own property. Body: `{ property: { name, address } }` |
| `GET` | `/properties` | paginated, scoped to current_user |
| `GET` | `/properties/:id` | own only |
| `PATCH` | `/properties/:id` | |
| `DELETE` | `/properties/:id` | cascades to rooms / leases / tickets |
| `GET` | `/properties/:id/documents` | S3 doc listing |

---

## Rooms — `/rooms`

| Verb | Path | Notes |
|---|---|---|
| `POST` | `/rooms` | Body: `{ room: { name, surface_area, rent, charges, property_id } }` |
| `GET` | `/rooms?property_id=…` | paginated, scoped |
| `PATCH` | `/rooms/:id` | |
| `DELETE` | `/rooms/:id` | |

---

## Leases — `/leases`

| Verb | Path | Role | Notes |
|---|---|---|---|
| `POST` | `/leases` | landlord | Body: `{ lease: { tenant_id, room_id, start_date, end_date, monthly_rent, monthly_charges, deposit, signed_at } }`. Fires `LeaseMailer.signed` to tenant. |
| `GET` | `/leases` | both | landlord → own rooms; tenant → own leases. Paginated. |
| `GET` | `/leases/:id` | both | scoped |
| `PATCH` | `/leases/:id` | landlord | |
| `DELETE` | `/leases/:id` | landlord | |
| `PATCH` | `/leases/:id/terminate` | landlord | sets `status=terminated`, `end_date=today`. Fires `LeaseMailer.terminated`. |

---

## Lease Applications — `/lease_applications`

| Verb | Path | Role | Notes |
|---|---|---|---|
| `POST` | `/lease_applications` | tenant | Body: `{ lease_application: { room_id, message } }`. Unique per `(tenant_id, room_id)`. Fires `LeaseApplicationMailer.submitted` to landlord. |
| `GET` | `/lease_applications` | both | scoped, paginated |
| `GET` | `/lease_applications/:id` | both | scoped |
| `PATCH` | `/lease_applications/:id` | tenant (owner) | update message |
| `DELETE` | `/lease_applications/:id` | tenant (owner) | |
| `PATCH` | `/lease_applications/:id/validate` | landlord | Body: `{ decision: "approved" \| "rejected" }`. Fires `LeaseApplicationMailer.validated` to tenant. |

---

## Rent Payments — `/rent_payments`

| Verb | Path | Role | Notes |
|---|---|---|---|
| `POST` | `/rent_payments` | landlord | pre-generates N monthly payments for a lease (`lease_id`, `months` default 12). Idempotent — `find_or_create_by(lease_id, due_date)`. |
| `GET` | `/rent_payments` | both | landlord → own properties; tenant → own. Optional `?status=pending\|paid\|late\|disputed`. Paginated. |
| `GET` | `/rent_payments/:id` | both | scoped |
| `PATCH` | `/rent_payments/:id/mark_paid` | landlord | Body: `{ payment_method: "virement"\|"prelevement"\|"cheque"\|"especes" }`. Sets `status=paid`, `paid_at=today`. Generates a PDF quittance and emails it to the tenant via `SendNotificationJob` → `ReceiptMailer.delivered`. |

---

## AI Agent — `/agent`

All endpoints authenticated. Server-side calls Claude (Anthropic API).

### `POST /agent/chat`

Body: `{ message: "…", history: [ { role, content }, … ] }`

Returns: `{ "reply": "…" }`

Orchestrator runs a tool-use loop (max 5 iterations). Tools registered in `ClarkAgent::ToolRegistry` are scoped server-side to the calling user.

| Tool | Purpose |
|---|---|
| `get_user_context` | wraps `ContextBuilder` |
| `list_properties` | landlord portfolio + active monthly revenue |
| `calculate_irl_revision` | IRL formula on a user-visible lease |
| `list_tickets` | open / filtered tickets |
| `create_ticket` | persist a ticket on a property (reporter = current user) |
| … additional tools (see `ToolDefinitions` / `ToolExecutor`) |

Returns `502` if Anthropic upstream raises.

### `GET /agent/context`

Returns `ContextBuilder` JSON for the current user (role, counts, recent items).

### `GET /agent/properties/summary`

Landlord-only synthesised view of the portfolio.

### `GET /agent/leases/:id/irl`

IRL revision computed inline. Query: `?base_irl=…&current_irl=…`.

### `POST /agent/receipts`

Body: `{ lease_id, period }`. Generates a PDF receipt via `ClarkAgent::ReceiptPdf`, uploads to S3, returns signed URL.

### `GET /agent/documents/:type`

Returns a signed S3 URL for a known document type.

### `POST /agent/notifications/send`

Body: `{ channel: "email"\|"sms", recipient, payload }`. Enqueues `SendNotificationJob` directly (admin/agent use).

### `GET /agent/tickets`, `POST /agent/tickets`, `GET /agent/tickets/:id`

CRUD on `Ticket` (property/tenant/category/description/priority/status). Creation fires `TicketMailer.created` to the landlord.

---

## Notification fan-out

All outbound mail/SMS goes through `SendNotificationJob` (`channel`, `recipient`, `payload`):

- `payload.mailer + action + args` → named mailer with positional or kwargs args.
- `payload.subject + body` (raw email fallback).
- SMS branch uses `TwilioSms` when `TWILIO_ACCOUNT_SID/AUTH_TOKEN/FROM` are set, otherwise logs and skips so dev/CI stays green.

ActionMailer delivery method:
- `test` — collects into `ActionMailer::Base.deliveries`.
- `production` — SendGrid SMTP (`smtp.sendgrid.net:587`, user `apikey`, pass `SENDGRID_API_KEY`).

---

## Env vars

| Var | Purpose |
|---|---|
| `DATABASE_URL` | Postgres |
| `REDIS_URL` | Sidekiq / cache |
| `SECRET_KEY_BASE` | Rails |
| `JWT_SECRET` | session tokens |
| `ANTHROPIC_API_KEY` | agent |
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_BUCKET` | S3 |
| `SENDGRID_API_KEY`, `MAIL_FROM`, `MAIL_DOMAIN`, `APP_HOST` | email |
| `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM` | SMS |
| `SENTRY_DSN` | error tracking (lograge + sentry-rails wired in production) |
