require 'rails_helper'

RSpec.describe LeaseIrlAnniversaryReminderJob, type: :job do
  let(:landlord) { create(:user, role: 'landlord', email: 'landlord@example.com') }
  let(:tenant)   { create(:user, :tenant) }
  let(:property) { create(:property, user: landlord) }
  let(:room)     { create(:room, property: property) }

  before { ActiveJob::Base.queue_adapter = :test }

  it 'enqueues a reminder for a lease whose start_date matches today exactly one year ago' do
    anniversary = create(:lease, room: room, tenant: tenant,
                                 start_date: Date.current - 1.year,
                                 status: 'active')

    expect do
      described_class.new.perform
    end.to have_enqueued_job(SendNotificationJob).with(
      hash_including(
        channel: 'email',
        recipient: landlord.email,
        payload: hash_including(mailer: 'LeaseMailer', action: 'irl_revision_due')
      )
    )
    expect(anniversary.id).to be_present
  end

  it 'skips leases younger than 12 months' do
    create(:lease, room: room, tenant: tenant,
                   start_date: 6.months.ago.to_date,
                   status: 'active')

    expect { described_class.new.perform }.not_to have_enqueued_job(SendNotificationJob)
  end

  it 'skips terminated leases on their anniversary' do
    create(:lease, room: room, tenant: tenant,
                   start_date: Date.current - 1.year,
                   status: 'terminated')

    expect { described_class.new.perform }.not_to have_enqueued_job(SendNotificationJob)
  end

  it 'skips leases not on their anniversary date' do
    # start_date is 1 year ago + 1 day
    create(:lease, room: room, tenant: tenant,
                   start_date: Date.current - 1.year - 1.day,
                   status: 'active')

    expect { described_class.new.perform }.not_to have_enqueued_job(SendNotificationJob)
  end
end
