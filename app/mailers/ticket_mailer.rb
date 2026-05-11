class TicketMailer < ApplicationMailer
  def created(ticket_id)
    @ticket   = Ticket.find(ticket_id)
    landlord  = @ticket.property.user
    mail(to: landlord.email, subject: "[Ticket] #{ticket_subject}")
  end

  def resolved(ticket_id)
    @ticket = Ticket.find(ticket_id)
    mail(to: @ticket.tenant.email, subject: "Ticket résolu : #{ticket_subject}")
  end

  def escalated(ticket_id)
    @ticket  = Ticket.find(ticket_id)
    landlord = @ticket.property.user
    mail(to: landlord.email, subject: "[ESCALATION] #{ticket_subject}")
  end

  private

  def ticket_subject
    @ticket.description.to_s.lines.first&.strip&.truncate(50) || @ticket.category.to_s.humanize
  end
end
