class TicketMailer < ApplicationMailer
  def created(ticket_id)
    @ticket   = Ticket.find(ticket_id)
    landlord  = @ticket.room.property.user
    mail(to: landlord.email, subject: "[Ticket] #{@ticket.title}")
  end

  def resolved(ticket_id)
    @ticket = Ticket.find(ticket_id)
    mail(to: @ticket.reporter.email, subject: "Ticket résolu : #{@ticket.title}")
  end
end
