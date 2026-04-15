# Clark Rent — API Backend

Rails API pour la plateforme Clark Rent : gestion locative intelligente avec agent conversationnel IA.

## Stack

- Ruby on Rails 7.1 (API mode)
- PostgreSQL
- AWS S3 (ActiveStorage)
- Anthropic Claude (agent IA)
- JWT (authentification)
- Sidekiq (jobs asynchrones)

## Installation

```bash
bundle install
cp .env.example .env
rails db:create db:migrate
rails server
```

## Branches

| Branche | Rôle |
|---|---|
| `main` | Production |
| `develop` | Intégration |
| `feature/*` | Features en cours |
| `release/vX.Y` | Préparation release |

## Milestones

- **v0.1** — CRUD Users, Properties, Auth JWT
- **v0.2** — Leases, Applications, Rooms
- **v0.3** — Agent IA (tickets, chat, IRL, quittances)
