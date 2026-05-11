module Api
  module V1
    module Agent
      class TicketsController < BaseController
        def index
          render json: paginate(scoped_tickets.order(created_at: :desc)), each_serializer: TicketSerializer
        end

        def show
          ticket = scoped_tickets.find(params[:id])
          render json: ticket, serializer: TicketSerializer
        end

        def create
          ticket = build_ticket
          if ticket.save
            notify_landlord(ticket)
            render json: ticket, serializer: TicketSerializer, status: :created
          else
            render json: { errors: ticket.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def build_ticket
          property = resolve_property
          Ticket.new(ticket_params.merge(tenant: current_user, property: property))
        end

        def resolve_property
          if ticket_params[:property_id]
            Property.find_by(id: ticket_params[:property_id])
          else
            current_user.leases.where(status: 'active').joins(:room).first&.room&.property
          end
        end

        def scoped_tickets
          if current_user.role == 'landlord'
            Ticket.for_owner(current_user)
          else
            Ticket.where(tenant: current_user)
          end
        end

        def notify_landlord(ticket)
          SendNotificationJob.perform_later(
            channel: 'email', recipient: ticket.property.user.email,
            payload: { mailer: 'TicketMailer', action: 'created', args: [ticket.id] }
          )
        end

        def ticket_params
          params.require(:ticket).permit(:property_id, :category, :description, :priority)
        end
      end
    end
  end
end
