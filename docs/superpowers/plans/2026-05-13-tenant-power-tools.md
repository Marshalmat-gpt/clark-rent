# Tenant Power Tools — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give tenants two new agent tools: add comments or close their own tickets, and send a direct message to their landlord.

**Architecture:** Two new methods added to `ToolExecutor` (scoped to `current_user` for IDOR safety). `message_owner` uses a new `OwnerMailer` with `deliver_later`. Both new tool specs added to `ToolRegistry::TOOL_SPECS`. All input sanitized before persist/send.

**Tech Stack:** Rails 7.2, ActionMailer, ActiveJob, RSpec, FactoryBot

---

## Context

**Existing patterns to follow:**
- `ToolExecutor` class methods: `def self.method_name(user, input)` → returns `{ content: { ... } }`
- IDOR pattern: `Ticket.where(tenant: user).find_by(id: ...)` (never find by id alone)
- Input sanitization: `.to_s.strip.first(N)` + whitelist enums
- Mail: `MailerClass.method(args).deliver_later` — all async
- `ToolRegistry::TOOL_SPECS` is a frozen array — must rewrite full constant when adding entries

**Key models:**
- `Ticket::STATUSES = %w[open assigned resolved closed]`
- `Ticket#data` — JSONB column, default `{}`
- `Lease → room → property → user` (owner)
- `user.active_lease` → most recent active lease

**Key files:**
- `app/services/clark_agent/tool_executor.rb` — add methods here
- `app/services/clark_agent/tool_registry.rb` — add specs to `TOOL_SPECS`
- `app/mailers/application_mailer.rb` — base class (layout 'mailer', from ENV)

---

## File Map

| Action | File | What changes |
|--------|------|-------------|
| Modify | `app/services/clark_agent/tool_executor.rb` | Add `update_ticket` + `message_owner` methods + wire in `case` |
| Modify | `app/services/clark_agent/tool_registry.rb` | Add 2 specs, count 10 → 12 |
| Modify | `spec/services/clark_agent/tool_registry_spec.rb` | Update count assertion 10 → 12, add new tool names |
| Create | `app/mailers/owner_mailer.rb` | `tenant_message` mailer |
| Create | `app/views/owner_mailer/tenant_message.html.erb` | HTML mail template |
| Create | `app/views/owner_mailer/tenant_message.text.erb` | Plain-text mail template |
| Create | `spec/services/clark_agent/tool_executor_spec.rb` | Tests for both new tools |
| Create | `spec/mailers/owner_mailer_spec.rb` | Mailer unit tests |

---

## Task 1: `update_ticket` tool

**Files:**
- Modify: `app/services/clark_agent/tool_executor.rb`
- Modify: `app/services/clark_agent/tool_registry.rb`
- Modify: `spec/services/clark_agent/tool_registry_spec.rb`
- Create: `spec/services/clark_agent/tool_executor_spec.rb`

- [ ] **Step 1: Write failing ToolExecutor spec**

Create `spec/services/clark_agent/tool_executor_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe ClarkAgent::ToolExecutor do
  let(:owner)    { create(:user, role: 'landlord') }
  let(:property) { create(:property, user: owner) }
  let(:room)     { create(:room, property: property) }
  let(:user)     { create(:user, :tenant) }
  let!(:lease)   { create(:lease, room: room, tenant: user, status: 'active') }

  describe "update_ticket" do
    let!(:ticket) { create(:ticket, tenant: user, property: property, status: 'open') }

    context 'action: close' do
      it 'closes the ticket and sets resolved_at' do
        result = described_class.execute(
          name: 'update_ticket',
          input: { 'ticket_id' => ticket.id, 'action' => 'close' },
          user: user, _role: 'tenant'
        )
        expect(result[:content][:status]).to eq('closed')
        expect(ticket.reload.status).to eq('closed')
        expect(ticket.reload.resolved_at).to be_present
      end

      it 'returns error for unknown ticket_id' do
        result = described_class.execute(
          name: 'update_ticket',
          input: { 'ticket_id' => 999_999, 'action' => 'close' },
          user: user, _role: 'tenant'
        )
        expect(result[:content][:error]).to be_present
      end

      it 'prevents IDOR — cannot close another tenant ticket' do
        other = create(:user, :tenant)
        other_ticket = create(:ticket, tenant: other, property: property, status: 'open')
        result = described_class.execute(
          name: 'update_ticket',
          input: { 'ticket_id' => other_ticket.id, 'action' => 'close' },
          user: user, _role: 'tenant'
        )
        expect(result[:content][:error]).to be_present
        expect(other_ticket.reload.status).to eq('open')
      end
    end

    context 'action: add_comment' do
      it 'appends comment with tenant metadata to ticket data' do
        result = described_class.execute(
          name: 'update_ticket',
          input: { 'ticket_id' => ticket.id, 'action' => 'add_comment', 'comment' => 'Toujours pas réparé.' },
          user: user, _role: 'tenant'
        )
        expect(result[:content][:comments_count]).to eq(1)
        comment = ticket.reload.data['comments'].first
        expect(comment['text']).to eq('Toujours pas réparé.')
        expect(comment['by']).to eq('tenant')
        expect(comment['at']).to be_present
      end

      it 'returns error when comment is blank' do
        result = described_class.execute(
          name: 'update_ticket',
          input: { 'ticket_id' => ticket.id, 'action' => 'add_comment', 'comment' => '   ' },
          user: user, _role: 'tenant'
        )
        expect(result[:content][:error]).to be_present
      end

      it 'truncates comment to 1000 chars' do
        described_class.execute(
          name: 'update_ticket',
          input: { 'ticket_id' => ticket.id, 'action' => 'add_comment', 'comment' => 'x' * 1500 },
          user: user, _role: 'tenant'
        )
        expect(ticket.reload.data['comments'].first['text'].length).to eq(1000)
      end
    end

    context 'unknown action' do
      it 'returns error for unrecognised action' do
        result = described_class.execute(
          name: 'update_ticket',
          input: { 'ticket_id' => ticket.id, 'action' => 'hack' },
          user: user, _role: 'tenant'
        )
        expect(result[:content][:error]).to include('hack')
      end
    end
  end
end
```

- [ ] **Step 2: Add `update_ticket` method to ToolExecutor**

Read `app/services/clark_agent/tool_executor.rb`. In the `execute` `case` block, add after `when 'get_document' then get_document(user, input)`:

```ruby
      when 'update_ticket'          then update_ticket(user, input)
```

Then add this private class method after the `get_document` method, before the owner tools section:

```ruby
    def self.update_ticket(user, input)
      ticket = Ticket.where(tenant: user).find_by(id: input['ticket_id'].to_i)
      return { content: { error: 'Ticket introuvable.' } } unless ticket

      case input['action'].to_s
      when 'close'
        return { content: { error: 'Ticket déjà fermé.' } } if ticket.status == 'closed'

        ticket.update!(status: 'closed', resolved_at: Time.current)
        {
          content: {
            ticket_id:  ticket.id,
            status:     ticket.status,
            resolved_at: ticket.resolved_at.strftime('%d/%m/%Y %H:%M'),
            message:    "Ticket ##{ticket.id} fermé. Merci de nous avoir informés."
          }
        }
      when 'add_comment'
        comment_text = input['comment'].to_s.strip.first(1000)
        return { content: { error: 'Commentaire vide.' } } if comment_text.blank?

        comments = (ticket.data['comments'] || [])
        comments << { 'text' => comment_text, 'by' => 'tenant', 'at' => Time.current.iso8601 }
        ticket.update!(data: ticket.data.merge('comments' => comments))
        {
          content: {
            ticket_id:      ticket.id,
            comments_count: comments.size,
            message:        "Commentaire ajouté au ticket ##{ticket.id}."
          }
        }
      else
        { content: { error: "Action inconnue : #{input['action']}. Utilisez 'close' ou 'add_comment'." } }
      end
    end
```

- [ ] **Step 3: Add `update_ticket` spec to ToolRegistry**

Read `app/services/clark_agent/tool_registry.rb`. In `TOOL_SPECS`, find the closing `].tap { |specs| specs.each(&:freeze) }.freeze` line. Insert this new spec hash **before** that closing line (i.e., as the 11th entry, after `generate_rent_receipt`):

```ruby
      {
        name: 'update_ticket',
        description: "Ajoute un commentaire à un ticket existant ou le ferme. Actions : 'add_comment' (ajouter une note), 'close' (marquer comme résolu).",
        input_schema: {
          type: 'object',
          properties: {
            ticket_id: { type: 'integer', description: 'ID du ticket' },
            action:    { type: 'string', enum: %w[add_comment close], description: "Action : 'add_comment' ou 'close'" },
            comment:   { type: 'string', description: 'Texte du commentaire (requis pour add_comment, max 1000 chars)' }
          },
          required: %w[ticket_id action]
        }
      },
```

- [ ] **Step 4: Update ToolRegistry spec count and tool name list**

Read `spec/services/clark_agent/tool_registry_spec.rb`. Make two changes:

Change `expect(specs.length).to eq(10)` → `expect(specs.length).to eq(11)`

In the owner tools name list, add `'update_ticket'` to the `include` call (or add a separate tenant tools check — `update_ticket` is a tenant tool so add it to the tenant names include):

Change:
```ruby
      expect(names).to include('get_my_lease', 'get_payment_history', 'create_ticket',
                               'get_ticket_status', 'get_document')
```
to:
```ruby
      expect(names).to include('get_my_lease', 'get_payment_history', 'create_ticket',
                               'get_ticket_status', 'get_document', 'update_ticket')
```

- [ ] **Step 5: Commit**

```bash
git add app/services/clark_agent/tool_executor.rb \
        app/services/clark_agent/tool_registry.rb \
        spec/services/clark_agent/tool_registry_spec.rb \
        spec/services/clark_agent/tool_executor_spec.rb
git commit -m "feat(agent): add update_ticket tool — tenant can comment/close own tickets"
```

---

## Task 2: `message_owner` tool + OwnerMailer

**Files:**
- Create: `app/mailers/owner_mailer.rb`
- Create: `app/views/owner_mailer/tenant_message.html.erb`
- Create: `app/views/owner_mailer/tenant_message.text.erb`
- Modify: `app/services/clark_agent/tool_executor.rb`
- Modify: `app/services/clark_agent/tool_registry.rb`
- Modify: `spec/services/clark_agent/tool_registry_spec.rb`
- Modify: `spec/services/clark_agent/tool_executor_spec.rb`
- Create: `spec/mailers/owner_mailer_spec.rb`

- [ ] **Step 1: Write failing OwnerMailer spec**

Create `spec/mailers/owner_mailer_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe OwnerMailer, type: :mailer do
  let(:owner)    { build_stubbed(:user, role: 'landlord', email: 'owner@example.com', first_name: 'Paul', last_name: 'Martin') }
  let(:tenant)   { build_stubbed(:user, :tenant, email: 'tenant@example.com', first_name: 'Alice', last_name: 'Dupont') }
  let(:property) { build_stubbed(:property, user: owner) }
  let(:lease)    { build_stubbed(:lease, tenant: tenant, room: build_stubbed(:room, property: property)) }
  let(:mail) do
    described_class.tenant_message(
      tenant:  tenant,
      owner:   owner,
      lease:   lease,
      subject: 'Question sur le chauffage',
      body:    'Bonjour, le radiateur ne fonctionne plus.'
    )
  end

  it 'sends to the owner email' do
    expect(mail.to).to eq(['owner@example.com'])
  end

  it 'sets reply-to as the tenant email' do
    expect(mail.reply_to).to eq(['tenant@example.com'])
  end

  it 'includes the subject in the mail subject line' do
    expect(mail.subject).to include('Question sur le chauffage')
  end

  it 'includes the body in the mail body' do
    expect(mail.body.encoded).to include('le radiateur ne fonctionne plus')
  end
end
```

- [ ] **Step 2: Create OwnerMailer**

Create `app/mailers/owner_mailer.rb`:

```ruby
class OwnerMailer < ApplicationMailer
  # Sends a tenant-authored message to their landlord via the Clark agent.
  # The tenant's email is set as reply-to so the owner can reply directly.
  def tenant_message(tenant:, owner:, lease:, subject:, body:)
    @tenant   = tenant
    @owner    = owner
    @lease    = lease
    @property = lease.property
    @subject  = subject
    @body     = body

    mail(
      to:       owner.email,
      reply_to: tenant.email,
      subject:  "[Clark] Message de votre locataire — #{subject}"
    )
  end
end
```

- [ ] **Step 3: Create mail views**

Create `app/views/owner_mailer/tenant_message.html.erb`:

```erb
<h2>Message de votre locataire</h2>
<p><strong>Bien :</strong> <%= @property.formatted_address %></p>
<p><strong>De :</strong> <%= @tenant.full_name %> &lt;<%= @tenant.email %>&gt;</p>
<p><strong>Objet :</strong> <%= @subject %></p>
<hr>
<%= simple_format h(@body) %>
<hr>
<p style="color:#888;font-size:0.9em">
  Message envoyé via Clark Rent. Répondre directement à cet email pour contacter votre locataire.
</p>
```

Create `app/views/owner_mailer/tenant_message.text.erb`:

```erb
Message de votre locataire — <%= @property.formatted_address %>

De : <%= @tenant.full_name %> (<%= @tenant.email %>)
Objet : <%= @subject %>

---

<%= @body %>

---
Message envoyé via Clark Rent.
Répondre directement à cet email pour contacter votre locataire.
```

- [ ] **Step 4: Add `message_owner` method to ToolExecutor**

Read `app/services/clark_agent/tool_executor.rb`. In the `case` block, add after `when 'update_ticket' then update_ticket(user, input)`:

```ruby
      when 'message_owner'          then message_owner(user, input)
```

Then add this class method after `update_ticket`:

```ruby
    def self.message_owner(user, input)
      lease = user.active_lease
      return { content: { error: 'Aucun bail actif trouvé.' } } unless lease

      subject = input['subject'].to_s.strip.first(200)
      body    = input['body'].to_s.strip.first(2000)
      return { content: { error: 'Sujet requis.' } } if subject.blank?
      return { content: { error: 'Message requis.' } } if body.blank?

      owner = lease.property.user

      OwnerMailer.tenant_message(
        tenant:  user,
        owner:   owner,
        lease:   lease,
        subject: subject,
        body:    body
      ).deliver_later

      {
        content: {
          message: "Message envoyé à votre propriétaire (#{owner.full_name}). Il recevra votre email sous quelques minutes.",
          subject: subject
        }
      }
    end
```

- [ ] **Step 5: Add `message_owner` tests to ToolExecutor spec**

Read `spec/services/clark_agent/tool_executor_spec.rb`. Append a new `describe "message_owner"` block inside the main `RSpec.describe` block (before the final `end`):

```ruby
  describe "message_owner" do
    it 'enqueues a tenant_message email to the owner' do
      mail_dbl = instance_double(ActionMailer::MessageDelivery)
      allow(OwnerMailer).to receive(:tenant_message).and_return(mail_dbl)
      allow(mail_dbl).to receive(:deliver_later)

      described_class.execute(
        name: 'message_owner',
        input: { 'subject' => 'Question', 'body' => 'Bonjour.' },
        user: user, _role: 'tenant'
      )

      expect(OwnerMailer).to have_received(:tenant_message).with(
        tenant:  user,
        owner:   owner,
        lease:   lease,
        subject: 'Question',
        body:    'Bonjour.'
      )
      expect(mail_dbl).to have_received(:deliver_later)
    end

    it 'returns success message with owner name' do
      mail_dbl = instance_double(ActionMailer::MessageDelivery)
      allow(OwnerMailer).to receive(:tenant_message).and_return(mail_dbl)
      allow(mail_dbl).to receive(:deliver_later)

      result = described_class.execute(
        name: 'message_owner',
        input: { 'subject' => 'Test', 'body' => 'Corps du message.' },
        user: user, _role: 'tenant'
      )
      expect(result[:content][:message]).to include(owner.full_name)
      expect(result[:content][:subject]).to eq('Test')
    end

    it 'returns error when user has no active lease' do
      no_lease_user = create(:user, :tenant)
      result = described_class.execute(
        name: 'message_owner',
        input: { 'subject' => 'Test', 'body' => 'Corps' },
        user: no_lease_user, _role: 'tenant'
      )
      expect(result[:content][:error]).to be_present
    end

    it 'returns error when subject is blank' do
      result = described_class.execute(
        name: 'message_owner',
        input: { 'subject' => '', 'body' => 'Corps' },
        user: user, _role: 'tenant'
      )
      expect(result[:content][:error]).to eq('Sujet requis.')
    end

    it 'truncates subject to 200 chars' do
      mail_dbl = instance_double(ActionMailer::MessageDelivery)
      allow(OwnerMailer).to receive(:tenant_message).and_return(mail_dbl)
      allow(mail_dbl).to receive(:deliver_later)

      result = described_class.execute(
        name: 'message_owner',
        input: { 'subject' => 'S' * 300, 'body' => 'Corps' },
        user: user, _role: 'tenant'
      )
      expect(result[:content][:subject].length).to eq(200)
    end
  end
```

- [ ] **Step 6: Add `message_owner` spec to ToolRegistry and update count**

Read `app/services/clark_agent/tool_registry.rb`. Add this 12th entry in `TOOL_SPECS` after `update_ticket`:

```ruby
      {
        name: 'message_owner',
        description: "Envoie un message email au propriétaire du logement de la part du locataire. Le propriétaire pourra répondre directement.",
        input_schema: {
          type: 'object',
          properties: {
            subject: { type: 'string', description: 'Objet du message (max 200 chars)' },
            body:    { type: 'string', description: 'Corps du message (max 2000 chars)' }
          },
          required: %w[subject body]
        }
      },
```

Read `spec/services/clark_agent/tool_registry_spec.rb`. Change count `eq(11)` → `eq(12)`. Add `'message_owner'` to the owner tools include list:

Change:
```ruby
      expect(names).to include('list_properties', 'get_property', 'list_applications',
                               'calculate_irl_revision', 'generate_rent_receipt')
```
to:
```ruby
      expect(names).to include('list_properties', 'get_property', 'list_applications',
                               'calculate_irl_revision', 'generate_rent_receipt', 'message_owner')
```

- [ ] **Step 7: Commit**

```bash
git add app/mailers/owner_mailer.rb \
        app/views/owner_mailer/ \
        app/services/clark_agent/tool_executor.rb \
        app/services/clark_agent/tool_registry.rb \
        spec/services/clark_agent/tool_registry_spec.rb \
        spec/services/clark_agent/tool_executor_spec.rb \
        spec/mailers/owner_mailer_spec.rb
git commit -m "feat(agent): add message_owner tool + OwnerMailer — tenant can message landlord"
```

---

## Self-Review

**Spec coverage:**
- `update_ticket` close: success ✓, unknown ticket ✓, IDOR ✓
- `update_ticket` add_comment: success with metadata ✓, blank comment ✓, 1000-char truncation ✓
- `update_ticket` unknown action: error ✓
- `message_owner`: email enqueued ✓, success response ✓, no active lease ✓, blank subject ✓, truncation ✓
- OwnerMailer: to/reply-to/subject/body ✓
- ToolRegistry: count 12 ✓, both new names in include lists ✓

**Type consistency:**
- `update_ticket` returns `{ content: { ticket_id:, status:, message: } }` for close and `{ content: { ticket_id:, comments_count:, message: } }` for add_comment ✓
- `message_owner` returns `{ content: { message:, subject: } }` ✓
- `OwnerMailer.tenant_message(tenant:, owner:, lease:, subject:, body:)` — keyword args consistent in mailer, executor, and spec ✓

**Security:**
- `Ticket.where(tenant: user).find_by(id: ...)` — IDOR safe ✓
- `comment_text.first(1000)`, `subject.first(200)`, `body.first(2000)` — input bounded ✓
- `reply_to` set to tenant email — owner can reply directly without exposing internal email routing ✓

**No placeholders:** All code blocks are complete implementations.
