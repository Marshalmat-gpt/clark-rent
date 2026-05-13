# Wire ToolExecutor into Orchestrator — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the orphaned ToolRegistry dispatch (5 tools, no security patches) with ToolExecutor (9 tools, all security patches applied), so tenants and owners get the full tool set.

**Architecture:** ToolRegistry becomes a spec-only catalogue (what Claude sees). Orchestrator's `run_tools` calls `ToolExecutor.execute` directly instead of `ToolRegistry.find.handler`. PROTECTED_TOOL_KEYS stripping stays in Orchestrator before the handoff.

**Tech Stack:** Ruby 3.2, Rails 7.1, anthropic gem, RSpec

---

## Context

### Current broken state
- `Orchestrator#run_tools` calls `ToolRegistry.find(name).handler.call(user:, **input)`
- `ToolRegistry` has **5 tools** with inline handler lambdas
- `ToolExecutor` has **9 tools** with security-patched implementations — but is **never called**
- Tenants see: `get_user_context`, `list_tickets`, `create_ticket` only
- Missing: `get_my_lease`, `get_payment_history`, `get_ticket_status`, `get_document`, `get_property`, `list_applications`, `calculate_irl_revision`, `generate_rent_receipt`

### Target state
- `ToolRegistry` is spec-only: array of `{ name:, description:, input_schema: }` hashes — no handlers
- `Orchestrator#run_tools` strips PROTECTED_TOOL_KEYS then calls `ToolExecutor.execute(name:, input:, user:, _role:)`
- All 9 ToolExecutor tools accessible from the agent

---

## File Map

| Action | File | Change |
|--------|------|--------|
| Modify | `app/services/clark_agent/tool_registry.rb` | Replace 5 tool structs+handlers with 10 spec-only hashes |
| Modify | `app/services/clark_agent/orchestrator.rb` | Rewrite `run_tools`; remove `safe_call` |
| Replace | `spec/services/clark_agent/tool_registry_spec.rb` | Spec for spec-only interface |
| Modify | `spec/services/clark_agent/orchestrator_spec.rb` | Test ToolExecutor dispatch + key stripping |

---

## Task 1: Rewrite ToolRegistry as spec-only catalogue

**Files:**
- Modify: `app/services/clark_agent/tool_registry.rb`
- Replace: `spec/services/clark_agent/tool_registry_spec.rb`

- [ ] **Step 1: Write the failing spec**

Replace `spec/services/clark_agent/tool_registry_spec.rb` with:

```ruby
require 'rails_helper'

RSpec.describe ClarkAgent::ToolRegistry do
  describe '.tool_specs' do
    subject(:specs) { described_class.tool_specs }

    it 'returns 10 specs' do
      expect(specs.length).to eq(10)
    end

    it 'includes all tenant tools' do
      names = specs.map { |s| s[:name] }
      expect(names).to include('get_my_lease', 'get_payment_history', 'create_ticket',
                               'get_ticket_status', 'get_document')
    end

    it 'includes all owner tools' do
      names = specs.map { |s| s[:name] }
      expect(names).to include('list_properties', 'get_property', 'list_applications',
                               'calculate_irl_revision', 'generate_rent_receipt')
    end

    it 'each spec has name, description, and input_schema' do
      specs.each do |spec|
        expect(spec).to have_key(:name)
        expect(spec).to have_key(:description)
        expect(spec).to have_key(:input_schema)
      end
    end

    it 'has no handler lambdas (dispatch is ToolExecutor responsibility)' do
      specs.each do |spec|
        expect(spec).not_to have_key(:handler)
      end
    end
  end
end
```

- [ ] **Step 2: Run spec to confirm failure**

```bash
bundle exec rspec spec/services/clark_agent/tool_registry_spec.rb --no-color
```

Expected: FAIL — `expected 10, got 5` or handler key found.

- [ ] **Step 3: Rewrite ToolRegistry**

Replace `app/services/clark_agent/tool_registry.rb` entirely:

```ruby
module ClarkAgent
  class ToolRegistry
    TOOL_SPECS = [
      # ── Tenant tools ────────────────────────────────────────────────────────
      {
        name: 'get_my_lease',
        description: "Renvoie les détails du bail actif du locataire (loyer, charges, adresse, dates, statut).",
        input_schema: { type: 'object', properties: {}, required: [] }
      },
      {
        name: 'get_payment_history',
        description: "Renvoie l'historique des paiements de loyer du locataire.",
        input_schema: {
          type: 'object',
          properties: {
            limit: { type: 'integer', description: 'Nombre max de paiements (défaut 10, max 100)' }
          },
          required: []
        }
      },
      {
        name: 'create_ticket',
        description: 'Crée un ticket de maintenance pour le logement du locataire et notifie le propriétaire.',
        input_schema: {
          type: 'object',
          properties: {
            category: { type: 'string', description: 'Catégorie du problème' },
            description: { type: 'string', description: 'Description détaillée du problème' },
            priority: { type: 'string', enum: %w[normal urgent], description: 'Urgence (défaut: normal)' }
          },
          required: %w[category description]
        }
      },
      {
        name: 'get_ticket_status',
        description: "Retourne les tickets de maintenance du locataire (ouverts par défaut).",
        input_schema: {
          type: 'object',
          properties: {
            ticket_id: { type: 'integer', description: 'ID du ticket (optionnel, sinon liste tous les ouverts)' }
          },
          required: []
        }
      },
      {
        name: 'get_document',
        description: "Renvoie une URL signée (1h) pour télécharger un document : bail, quittance, attestation de résidence, ou état des lieux.",
        input_schema: {
          type: 'object',
          properties: {
            document_type: {
              type: 'string',
              enum: %w[lease receipt residence_certificate inventory],
              description: 'Type de document'
            },
            month: { type: 'string', description: 'Mois YYYY-MM (requis pour les quittances)' }
          },
          required: %w[document_type]
        }
      },
      # ── Owner tools ──────────────────────────────────────────────────────────
      {
        name: 'list_properties',
        description: "Liste les propriétés du propriétaire avec alertes (bail expirant, tickets ouverts).",
        input_schema: {
          type: 'object',
          properties: {
            status: { type: 'string', enum: %w[active expired all], description: 'Filtre par statut de bail (optionnel)' }
          },
          required: []
        }
      },
      {
        name: 'get_property',
        description: "Détail complet d'une propriété : bail actif, coordonnées locataire, 5 tickets récents.",
        input_schema: {
          type: 'object',
          properties: {
            property_id: { type: 'integer', description: 'ID de la propriété' }
          },
          required: %w[property_id]
        }
      },
      {
        name: 'list_applications',
        description: "Liste les candidatures de location pour un bail.",
        input_schema: {
          type: 'object',
          properties: {
            lease_id: { type: 'integer', description: 'ID du bail' },
            status: { type: 'string', enum: %w[pending approved rejected], description: 'Filtre par statut (optionnel)' }
          },
          required: %w[lease_id]
        }
      },
      {
        name: 'calculate_irl_revision',
        description: "Calcule la révision de loyer via l'indice IRL pour un bail donné.",
        input_schema: {
          type: 'object',
          properties: {
            lease_id: { type: 'integer', description: 'ID du bail' }
          },
          required: %w[lease_id]
        }
      },
      {
        name: 'generate_rent_receipt',
        description: "Génère la quittance de loyer d'un mois et l'envoie au locataire par email.",
        input_schema: {
          type: 'object',
          properties: {
            lease_id: { type: 'integer', description: 'ID du bail' },
            month: { type: 'string', description: 'Mois au format YYYY-MM' }
          },
          required: %w[lease_id month]
        }
      }
    ].freeze

    def self.tool_specs
      TOOL_SPECS
    end
  end
end
```

- [ ] **Step 4: Run spec to confirm pass**

```bash
bundle exec rspec spec/services/clark_agent/tool_registry_spec.rb --no-color
```

Expected: `5 examples, 0 failures`

- [ ] **Step 5: Commit**

```bash
git add app/services/clark_agent/tool_registry.rb spec/services/clark_agent/tool_registry_spec.rb
git commit -m "refactor(agent): ToolRegistry becomes spec-only catalogue (10 tools, no handlers)"
```

---

## Task 2: Wire Orchestrator to dispatch via ToolExecutor

**Files:**
- Modify: `app/services/clark_agent/orchestrator.rb`
- Modify: `spec/services/clark_agent/orchestrator_spec.rb`

- [ ] **Step 1: Write failing specs**

Add these two examples to `spec/services/clark_agent/orchestrator_spec.rb` inside the existing `describe ClarkAgent::Orchestrator` block. If the spec file stubs `ToolRegistry`, replace those stubs too — the orchestrator no longer calls `ToolRegistry.find`.

```ruby
describe '#chat tool dispatch' do
  let(:user) { build_stubbed(:user, role: 'tenant', first_name: 'Alice') }
  let(:orchestrator) { described_class.new(user: user) }

  let(:tool_use_response) do
    {
      'stop_reason' => 'tool_use',
      'content' => [
        { 'type' => 'tool_use', 'id' => 'toolu_01', 'name' => 'get_my_lease', 'input' => {} }
      ]
    }
  end
  let(:end_turn_response) do
    { 'stop_reason' => 'end_turn', 'content' => [{ 'type' => 'text', 'text' => 'Votre bail est actif.' }] }
  end

  before do
    allow(orchestrator).to receive_message_chain(:client, :messages)
      .and_return(tool_use_response, end_turn_response)
    allow(ClarkAgent::ToolExecutor).to receive(:execute).and_return({ content: { id: 1 } })
  end

  it 'dispatches tool call to ToolExecutor' do
    orchestrator.chat('Montre mon bail')
    expect(ClarkAgent::ToolExecutor).to have_received(:execute).with(
      name: 'get_my_lease',
      input: {},
      user: user,
      _role: user.role
    )
  end

  it 'strips PROTECTED_TOOL_KEYS before dispatching' do
    injected_response = {
      'stop_reason' => 'tool_use',
      'content' => [
        {
          'type' => 'tool_use',
          'id' => 'toolu_02',
          'name' => 'get_my_lease',
          'input' => { 'user' => 'injected', 'role' => 'admin', 'current_user' => 'hacked', 'limit' => 5 }
        }
      ]
    }
    allow(orchestrator).to receive_message_chain(:client, :messages)
      .and_return(injected_response, end_turn_response)

    orchestrator.chat('Montre mon bail')

    expect(ClarkAgent::ToolExecutor).to have_received(:execute).with(
      name: 'get_my_lease',
      input: { 'limit' => 5 },
      user: user,
      _role: user.role
    )
  end
end
```

- [ ] **Step 2: Run specs to confirm failure**

```bash
bundle exec rspec spec/services/clark_agent/orchestrator_spec.rb --no-color
```

Expected: FAIL — `ToolExecutor` never receives `execute` (Orchestrator still calls `ToolRegistry.find`).

- [ ] **Step 3: Rewrite `run_tools` and remove `safe_call` in Orchestrator**

In `app/services/clark_agent/orchestrator.rb`, replace the `run_tools` private method and remove `safe_call`:

Find this block:

```ruby
    def run_tools(blocks)
      blocks.map do |block|
        tool = ToolRegistry.find(block['name'])
        result = if tool
                   safe_call(tool, block['input'] || {})
                 else
                   { error: "Unknown tool #{block['name']}" }
                 end
        {
          type: 'tool_result',
          tool_use_id: block['id'],
          content: result.to_json
        }
      end
    end

    def safe_call(tool, input)
      # Strip keys that could override the authenticated user or bypass authorization
      safe_input = input.transform_keys(&:to_sym).except(*PROTECTED_TOOL_KEYS)
      tool.handler.call(user: user, **safe_input)
    rescue StandardError => e
      { error: "#{e.class}: #{e.message}" }
    end
```

Replace with:

```ruby
    def run_tools(blocks)
      blocks.map do |block|
        # Strip keys that must never be overridden by LLM-controlled input,
        # then pass string-keyed hash to ToolExecutor (which uses input['key'] access).
        safe_input = (block['input'] || {})
                       .transform_keys(&:to_sym)
                       .except(*PROTECTED_TOOL_KEYS)
                       .transform_keys(&:to_s)

        result = ToolExecutor.execute(
          name: block['name'],
          input: safe_input,
          user: user,
          _role: user.role
        )

        {
          type: 'tool_result',
          tool_use_id: block['id'],
          content: result.to_json
        }
      end
    end
```

- [ ] **Step 4: Run specs to confirm pass**

```bash
bundle exec rspec spec/services/clark_agent/orchestrator_spec.rb --no-color
```

Expected: all examples pass.

- [ ] **Step 5: Run full suite to catch regressions**

```bash
bundle exec rspec --no-color 2>&1 | tail -10
```

Expected: `0 failures`. If `tool_registry_spec.rb` now fails because it references `ToolRegistry.find` — update those examples to use `ToolRegistry.tool_specs` instead.

- [ ] **Step 6: Commit**

```bash
git add app/services/clark_agent/orchestrator.rb spec/services/clark_agent/orchestrator_spec.rb
git commit -m "feat(agent): dispatch tool calls via ToolExecutor — 9 tools now live, PROTECTED_TOOL_KEYS enforced"
```

---

## Self-Review Notes

**Spec coverage:**
- ToolRegistry: 5 assertions cover count, tenant names, owner names, structure, no handlers ✓
- Orchestrator: dispatch routing ✓, PROTECTED_TOOL_KEYS stripping ✓

**Type consistency:**
- `ToolExecutor.execute(name:, input:, user:, _role:)` — signature matches existing implementation ✓
- `input` passed as `Hash` with string keys — matches `input['key']` access in ToolExecutor ✓
- `PROTECTED_TOOL_KEYS = %i[user role _role current_user]` — symbols stripped before `.transform_keys(&:to_s)` ✓

**No placeholders:** All code blocks are complete implementations.
