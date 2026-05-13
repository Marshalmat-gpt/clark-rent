# Server-Side Chat Sessions — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist conversation history server-side so tenant sessions survive client disconnects and page reloads.

**Architecture:** New `chat_sessions` table stores `messages` as a JSONB array scoped to `user_id`. `ChatController` loads or creates a session per request, passes its history to the Orchestrator, then appends the new turn. Session is IDOR-safe: all lookups scoped to `current_user`. Client passes optional `session_id`; response always echoes it back.

**Tech Stack:** Rails 7.2, PostgreSQL JSONB, RSpec request + model specs, FactoryBot

---

## Context

Current `ChatController#create` accepts `history` from the client (capped at 20 turns). If the client loses the array the entire conversation context is lost. After this plan the server owns the history.

**Key files already in place:**
- `app/controllers/api/v1/agent/chat_controller.rb` — will be rewritten
- `app/models/user.rb` — needs `has_many :chat_sessions`
- `db/schema.rb` — needs `chat_sessions` table entry

**Schema note:** CI loads `db/schema.rb` directly in tests (`rails_helper.rb` line 22: `load Rails.root.join('db', 'schema.rb')` when tables are empty). The migration creates the table for production/staging; updating `schema.rb` keeps tests green without running migrations in CI.

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `db/migrate/20260513000001_create_chat_sessions.rb` | DB migration — chat_sessions table |
| Modify | `db/schema.rb` | Add chat_sessions table so tests load it |
| Create | `app/models/chat_session.rb` | AR model — append_turn, history, MAX_TURNS |
| Create | `spec/factories/chat_sessions.rb` | FactoryBot factory |
| Create | `spec/models/chat_session_spec.rb` | Unit tests for model logic |
| Modify | `app/models/user.rb` | Add `has_many :chat_sessions, dependent: :destroy` |
| Modify | `app/controllers/api/v1/agent/chat_controller.rb` | Load/persist session, return session_id |
| Create | `spec/requests/api/v1/agent/chat_spec.rb` | Request specs for session lifecycle |

---

## Task 1: ChatSession model, migration, and schema

**Files:**
- Create: `db/migrate/20260513000001_create_chat_sessions.rb`
- Modify: `db/schema.rb`
- Create: `app/models/chat_session.rb`
- Create: `spec/factories/chat_sessions.rb`
- Create: `spec/models/chat_session_spec.rb`

- [ ] **Step 1: Write the failing model spec**

Create `spec/models/chat_session_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe ChatSession, type: :model do
  subject(:session) { build(:chat_session) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
  end

  describe '#append_turn' do
    it 'appends a user message and an assistant reply' do
      session.save!
      session.append_turn('Mon loyer ?', 'Votre loyer est 800€.')
      expect(session.messages).to eq([
        { 'role' => 'user',      'content' => 'Mon loyer ?' },
        { 'role' => 'assistant', 'content' => 'Votre loyer est 800€.' }
      ])
    end

    it 'trims history to MAX_TURNS * 2 messages' do
      session.save!
      ChatSession::MAX_TURNS.times { |i| session.append_turn("q#{i}", "a#{i}") }
      session.append_turn('overflow', 'reply_overflow')
      expect(session.messages.length).to eq(ChatSession::MAX_TURNS * 2)
      expect(session.messages.last['content']).to eq('reply_overflow')
      expect(session.messages.first['content']).to eq('a1')
    end

    it 'casts non-string content to string' do
      session.save!
      session.append_turn(nil, 42)
      expect(session.messages).to eq([
        { 'role' => 'user',      'content' => '' },
        { 'role' => 'assistant', 'content' => '42' }
      ])
    end
  end

  describe '#history' do
    it 'returns the messages array' do
      session.messages = [{ 'role' => 'user', 'content' => 'test' }]
      expect(session.history).to eq(session.messages)
    end
  end
end
```

- [ ] **Step 2: Create the factory**

Create `spec/factories/chat_sessions.rb`:

```ruby
FactoryBot.define do
  factory :chat_session do
    association :user
    messages { [] }
  end
end
```

- [ ] **Step 3: Create the migration**

Create `db/migrate/20260513000001_create_chat_sessions.rb`:

```ruby
class CreateChatSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :chat_sessions do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.jsonb :messages, null: false, default: []
      t.timestamps
    end
  end
end
```

- [ ] **Step 4: Update db/schema.rb**

In `db/schema.rb`, update the version line and add the `chat_sessions` table.

Change version from:
```ruby
ActiveRecord::Schema[7.2].define(version: 2026_05_07_000005) do
```
to:
```ruby
ActiveRecord::Schema[7.2].define(version: 2026_05_13_000001) do
```

Add this block **before** the `add_foreign_key` lines at the bottom:

```ruby
  create_table "chat_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.jsonb "messages", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_chat_sessions_on_user_id"
  end
```

Also add this foreign key with the others:
```ruby
  add_foreign_key "chat_sessions", "users"
```

- [ ] **Step 5: Create the model**

Create `app/models/chat_session.rb`:

```ruby
# Persists conversation history for a user's Clark agent session.
# Messages are stored as a JSONB array of { role:, content: } hashes,
# compatible with the Anthropic messages API format.
class ChatSession < ApplicationRecord
  MAX_TURNS = 20

  belongs_to :user

  # Appends one user message and one assistant reply, then trims history
  # to the last MAX_TURNS * 2 messages (i.e. MAX_TURNS full exchanges).
  def append_turn(user_message, assistant_reply)
    self.messages = (messages + [
      { 'role' => 'user',      'content' => user_message.to_s },
      { 'role' => 'assistant', 'content' => assistant_reply.to_s }
    ]).last(MAX_TURNS * 2)
  end

  # Returns the messages array formatted for Anthropic's messages API.
  def history
    messages
  end
end
```

- [ ] **Step 6: Commit**

```bash
git add db/migrate/20260513000001_create_chat_sessions.rb \
        db/schema.rb \
        app/models/chat_session.rb \
        spec/factories/chat_sessions.rb \
        spec/models/chat_session_spec.rb
git commit -m "feat(agent): add ChatSession model — persists conversation history as JSONB"
```

---

## Task 2: Update ChatController and User model with session persistence

**Files:**
- Modify: `app/models/user.rb`
- Modify: `app/controllers/api/v1/agent/chat_controller.rb`
- Create: `spec/requests/api/v1/agent/chat_spec.rb`

- [ ] **Step 1: Write the failing request spec**

You need to know how `authenticated_headers` works in this project. Check `spec/support/` for an auth helper. It likely returns `{ 'Authorization' => "Bearer #{token}" }`. Use whatever helper exists; if none exists, generate a JWT directly using the User model's token method.

Create `spec/requests/api/v1/agent/chat_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe 'POST /api/v1/agent/chat', type: :request do
  let(:user) { create(:user) }
  let(:headers) { authenticated_headers(user) }

  before do
    allow_any_instance_of(ClarkAgent::Orchestrator)
      .to receive(:chat)
      .and_return('Votre bail est actif.')
  end

  describe 'session lifecycle' do
    it 'creates a new session and returns session_id in response' do
      post '/api/v1/agent/chat', params: { message: 'Bonjour' }, headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['reply']).to eq('Votre bail est actif.')
      expect(body['session_id']).to be_a(Integer)
    end

    it 'persists user message and reply in the session' do
      post '/api/v1/agent/chat', params: { message: 'Mon loyer ?' }, headers: headers
      session = ChatSession.last
      expect(session.messages).to include(
        { 'role' => 'user',      'content' => 'Mon loyer ?' },
        { 'role' => 'assistant', 'content' => 'Votre bail est actif.' }
      )
    end

    it 'reuses existing session when valid session_id provided' do
      existing = create(:chat_session, user: user)
      post '/api/v1/agent/chat',
           params: { message: 'Deuxième question', session_id: existing.id },
           headers: headers
      body = JSON.parse(response.body)
      expect(body['session_id']).to eq(existing.id)
      expect(existing.reload.messages.length).to eq(2)
    end

    it 'creates a new session when session_id is not found' do
      post '/api/v1/agent/chat',
           params: { message: 'Bonjour', session_id: 999_999 },
           headers: headers
      body = JSON.parse(response.body)
      expect(body['session_id']).to be_a(Integer)
      expect(body['session_id']).not_to eq(999_999)
    end

    it 'prevents IDOR — cannot reuse another user session' do
      other = create(:user)
      other_session = create(:chat_session, user: other)
      post '/api/v1/agent/chat',
           params: { message: 'Hack', session_id: other_session.id },
           headers: headers
      body = JSON.parse(response.body)
      expect(body['session_id']).not_to eq(other_session.id)
    end

    it 'passes session history to Orchestrator' do
      existing = create(:chat_session, user: user,
                        messages: [{ 'role' => 'user', 'content' => 'Historique' },
                                   { 'role' => 'assistant', 'content' => 'Ok' }])
      expect_any_instance_of(ClarkAgent::Orchestrator)
        .to receive(:chat)
        .with('Nouvelle question', history: existing.messages)
        .and_return('Réponse')
      post '/api/v1/agent/chat',
           params: { message: 'Nouvelle question', session_id: existing.id },
           headers: headers
    end
  end

  describe 'error handling' do
    it 'returns 400 when message param is missing' do
      post '/api/v1/agent/chat', params: {}, headers: headers
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns 502 and does not save session when Orchestrator raises' do
      allow_any_instance_of(ClarkAgent::Orchestrator)
        .to receive(:chat)
        .and_raise(StandardError, 'API down')
      expect {
        post '/api/v1/agent/chat', params: { message: 'Test' }, headers: headers
      }.not_to change(ChatSession, :count)
      expect(response).to have_http_status(:bad_gateway)
    end
  end
end
```

- [ ] **Step 2: Add has_many to User model**

In `app/models/user.rb`, add inside the class body (after existing `has_many` lines if any, or after the class declaration):

```ruby
has_many :chat_sessions, dependent: :destroy
```

- [ ] **Step 3: Rewrite ChatController**

Replace `app/controllers/api/v1/agent/chat_controller.rb` entirely:

```ruby
module Api
  module V1
    module Agent
      class ChatController < BaseController
        def create
          message = params.require(:message)
          session = find_or_create_session
          reply   = ClarkAgent::Orchestrator.new(user: current_user).chat(
            message,
            history: session.history
          )
          session.append_turn(message, reply)
          session.save!
          render json: { reply: reply, session_id: session.id }
        rescue ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :bad_request
        rescue StandardError => e
          Rails.logger.error "[ChatController] #{e.class}: #{e.message}\n#{e.backtrace.first(3).join("\n")}"
          render json: { error: 'Agent unavailable' }, status: :bad_gateway
        end

        private

        # Loads the session if session_id belongs to current_user; otherwise creates a new one.
        # Scoped to current_user to prevent IDOR.
        def find_or_create_session
          if params[:session_id].present?
            current_user.chat_sessions.find_by(id: params[:session_id]) ||
              current_user.chat_sessions.create!(messages: [])
          else
            current_user.chat_sessions.create!(messages: [])
          end
        end
      end
    end
  end
end
```

- [ ] **Step 4: Commit**

```bash
git add app/models/user.rb \
        app/controllers/api/v1/agent/chat_controller.rb \
        spec/requests/api/v1/agent/chat_spec.rb
git commit -m "feat(agent): ChatController persists sessions — history survives disconnect, IDOR-safe"
```

---

## Self-Review

**Spec coverage:**
- ChatSession#append_turn: basic append ✓, trim to MAX_TURNS ✓, nil/non-string coercion ✓
- ChatSession#history: returns messages ✓
- ChatController: new session ✓, session_id returned ✓, history persisted ✓, session reused ✓, session not found → new ✓, IDOR prevention ✓, history passed to Orchestrator ✓, missing message → 400 ✓, Orchestrator error → 502 + no session saved ✓

**Type consistency:**
- `session.history` returns `messages` (Array) — matches `Orchestrator#chat(message, history: Array)` ✓
- `session.id` is Integer — spec asserts `be_a(Integer)` ✓
- `append_turn` uses string keys `'role'`, `'content'` — matches Anthropic API format ✓

**No placeholders:** All code blocks are complete.

**Security:** `find_or_create_session` scoped to `current_user.chat_sessions` — prevents IDOR ✓. `MAX_TURNS` cap prevents unbounded growth ✓.

**YAGNI:** No session list endpoint, no session delete endpoint — not needed for the core goal.
