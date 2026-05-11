# Escalate stale, urgent tickets that have been open too long.
#
# Scope:
#   priority = 'urgent' AND status IN ('open','assigned')
#   AND created_at < SLA_WINDOW.ago
#   AND data->>'escalated_at' IS NULL
#
# For each match: enqueue SendNotificationJob -> TicketMailer.escalated
# to the property owner, then mark the ticket as escalated in `data`
# so we don't double-fire on the next run.
#
# Intended for a Sidekiq-cron schedule (every 6h).
class TicketSlaEscalationJob < ApplicationJob
  queue_as :default

  SLA_WINDOW = 48.hours

  def perform
    Ticket.where(priority: 'urgent', status: %w[open assigned])
          .where('created_at < ?', SLA_WINDOW.ago)
          .where("(data->>'escalated_at') IS NULL")
          .find_each(&method(:escalate))
  end

  private

  def escalate(ticket)
    landlord_email = ticket.property&.user&.email
    return if landlord_email.blank?

    SendNotificationJob.perform_later(
      channel: 'email',
      recipient: landlord_email,
      payload: { mailer: 'TicketMailer', action: 'escalated', args: [ticket.id] }
    )

    data = ticket.data.is_a?(Hash) ? ticket.data : {}
    ticket.update!(data: data.merge('escalated_at' => Time.current.iso8601))
  end
end
