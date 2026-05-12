---
name: security-scan
description: Scoped security scan for clark-rent — checks auth, agent endpoints, IDOR, input validation, secrets
disable-model-invocation: false
---

# Clark-Rent Security Scan

Focused security review for clark-rent codebase.

## Scope

Review these paths in order:

1. **Agent endpoints** — `app/controllers/api/v1/agent/`
   - Error detail leaks in rescue blocks
   - History/input size caps
   - Rate limiting present

2. **Authentication** — `app/controllers/concerns/`, `app/models/user.rb`
   - JWT handling
   - `current_user` scope on all DB queries

3. **Document/file access** — `app/controllers/api/v1/agent/documents_controller.rb`
   - IDOR: does user own the resource?
   - Path traversal via raw params

4. **LLM prompt** — `app/services/clark_agent/system_prompt.rb`, `orchestrator.rb`
   - User-controlled input sanitized before interpolation
   - Tool input whitelist (`PROTECTED_TOOL_KEYS`)

5. **Secrets** — `config/`, `app/services/clark_agent/`
   - No hardcoded API keys
   - `ENV.fetch` with empty-string default for test compat

6. **Input validation** — `app/services/clark_agent/tool_executor.rb`
   - String truncation, whitelist values, integer bounds

## Output Format

For each issue found:

```
[CRITICAL/HIGH/MEDIUM/LOW] <location>: <description>
Fix: <specific change>
```

## Known Fixed Issues (skip)

- `chat_controller.rb`: error detail leak — patched commit 1502afbb
- `documents_controller.rb`: raw key IDOR — patched commit 466c21a3
- `system_prompt.rb`: prompt injection — patched commit cf19f0ec
- `rack_attack.rb`: no rate limit — patched commit 41f08c94
- `notifications_controller.rb`: permit! — patched commit 208775c1
- `orchestrator.rb`: tool input injection, empty API key — patched commit 82cd19c7
- `tool_executor.rb`: lease IDOR, unbounded input — patched commit 6245a9a0
