# Emails the landlord on the calendar anniversary of an active lease so
# they can review the IRL revision for the upcoming year.
#
# Match rule
#   lease.status == 'active'
#   lease.start_date is at least one year ago
#   lease.start_date.month == Date.current.month
#   lease.start_date.day   == Date.current.day
#
# Dedup
#   Lease has no jsonb column today; idempotency is achieved by
#   the job firing once per anniversary day — running it multiple
#   times in the same day re-sends, which we accept (cron fires
#   once per day at 08:00 Paris).
class LeaseIrlAnniversaryReminderJob < ApplicationJob
  queue_as :default

  def perform
    today = Time.zone.today
    Lease.active.where('start_date <= ?', today - 1.year).find_each do |lease|
      next unless lease.start_date.month == today.month
      next unless lease.start_date.day   == today.day

      notify(lease)
    end
  end

  private

  def notify(lease)
    landlord_email = lease.room.property.user.email
    SendNotificationJob.perform_later(
      channel: 'email',
      recipient: landlord_email,
      payload: { mailer: 'LeaseMailer', action: 'irl_revision_due', args: [lease.id] }
    )
  end
end
