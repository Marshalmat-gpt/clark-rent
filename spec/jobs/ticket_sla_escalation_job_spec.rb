require 'rails_helper'

RSpec.describe TicketSlaEscalationJob, type: :job do
  let(:landlord) { create(:user, role: 'landlord', email: 'landlord@example.com') }
  let(:tenant)   { create(:user, :tenant) }
  let(:property) { create(:property, user: landlord) }

  before { ActiveJob::Base.queue_adapter = :test }

  def make_ticket(**attrs)
    attrs = { priority: 'urgent', status: 'open', tenant: tenant, property: property }.merge(attrs)
    ticket = create(:ticket, **attrs)
    ticket.update_columns(created_at: 3.days.ago) if attrs[:stale] != false
    ticket
  end

  it 'enqueues escalation mail for urgent + open + > 48h old tickets' do
    target = make_ticket
    expect do
      described_class.new.perform
    end.to have_enqueued_job(SendNotificationJob).with(
      hash_including(channel: 'email', recipient: landlord.email,
                     payload: hash_including(mailer: 'TicketMailer', action: 'escalated'))
    )
    expect(target.reload.data['escalated_at']).to be_present
  end

  it 'skips tickets already escalated (data->>escalated_at present)' do
    already = make_ticket
    already.update_columns(data: { 'escalated_at' => Time.current.iso8601 })

    expect { described_class.new.perform }.not_to have_enqueued_job(SendNotificationJob)
  end

  it 'skips non-urgent or recently created tickets' do
    fresh   = create(:ticket, priority: 'urgent', status: 'open', tenant: tenant, property: property)
    normal  = make_ticket(priority: 'normal')

    expect { described_class.new.perform }.not_to have_enqueued_job(SendNotificationJob)
    expect(fresh.reload.data['escalated_at']).to be_nil
    expect(normal.reload.data['escalated_at']).to be_nil
  end

  it 'skips resolved tickets even if old' do
    old_resolved = make_ticket(status: 'resolved')
    expect { described_class.new.perform }.not_to have_enqueued_job(SendNotificationJob)
    expect(old_resolved.reload.data['escalated_at']).to be_nil
  end
end
