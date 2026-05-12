---
name: migrate
description: Rails database migration workflow — generate, review, and run migrations safely
disable-model-invocation: false
---

# Migration Workflow

Run a safe Rails migration workflow.

## Steps

1. **Generate** the migration:
   ```bash
   rails generate migration <MigrationName>
   ```

2. **Review** the generated file in `db/migrate/` — the `rails-migration-reviewer` agent will automatically assess it for safety.

3. **Run** the migration:
   - Development: `rails db:migrate`
   - Production: ensure a DB backup exists first, then deploy with migration

4. **Update schema**: `db:migrate` updates `db/schema.rb` automatically — commit both.

5. **Verify**: `rails db:migrate:status` — confirm migration is `up`.

## Safety Rules

- Never run a FAIL-verdict migration without fixing it first
- Always test rollback: `rails db:rollback` then `rails db:migrate`
- For large tables (>10k rows): use `algorithm: :concurrently` + `disable_ddl_transaction!`
- For NOT NULL columns on existing tables: add with default first, backfill, then add constraint

## Commit Template

```
db: add <migration_name> migration

- <what changed and why>
- Reversible: yes/no
```
