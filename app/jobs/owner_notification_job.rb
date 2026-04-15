class OwnerNotificationJob < ApplicationJob
  queue_as :default

  def perform(owner_id:, ticket_id:, channel: :email)
    owner  = User.find(owner_id)
    ticket = Ticket.includes(:property, :tenant).find(ticket_id)

    case channel.to_sym
    when :email
      OwnerMailer.new_ticket(owner: owner, ticket: ticket).deliver_now
    when :sms
      TwilioService.send_sms(
        to:   owner.phone,
        body: "[Clark] Nouveau ticket #{ticket.priority == 'urgent' ? '🚨 URGENT' : ''}: #{ticket.category} au #{ticket.property.formatted_address}"
      )
    end
  end
end
