# Thin shim that forwards owner-notification requests from ToolExecutor
# to the canonical SendNotificationJob dispatcher.
class OwnerNotificationJob < ApplicationJob
  queue_as :default

  def perform(owner_id:, ticket_id:, channel: :email)
    owner  = User.find(owner_id)
    ticket = Ticket.find(ticket_id)
    dispatch_for(channel.to_sym, owner: owner, ticket: ticket)
  end

  private

  def dispatch_for(channel, owner:, ticket:)
    case channel
    when :email then enqueue_email(owner, ticket)
    when :sms   then enqueue_sms(owner, ticket)
    end
  end

  def enqueue_email(owner, ticket)
    SendNotificationJob.perform_later(
      channel: 'email',
      recipient: owner.email,
      payload: { mailer: 'TicketMailer', action: 'created', args: [ticket.id] }
    )
  end

  def enqueue_sms(owner, ticket)
    SendNotificationJob.perform_later(
      channel: 'sms',
      recipient: owner.email,
      payload: { body: "Nouveau ticket : #{ticket.description.to_s.first(120)}" }
    )
  end
end
