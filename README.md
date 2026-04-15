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
# Remplir les variables dans .env
rails db:create db:migrate
rails server
```

## Structure

```
app/
  controllers/api/v1/        # Endpoints REST
  controllers/api/v1/agent/  # Endpoints agent IA
  models/                    # Modèles ActiveRecord
  services/clark_agent/      # Orchestrateur LLM + tools
  jobs/                      # ActiveJobs (notifications)
  mailers/                   # Emails
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
