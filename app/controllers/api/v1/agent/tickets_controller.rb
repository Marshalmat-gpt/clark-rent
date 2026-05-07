module Api
  module V1
    module Agent
      class TicketsController < BaseController
        def index
          render json: scoped_tickets.order(created_at: :desc), each_serializer: TicketSerializer
        end

        def show
          ticket = scoped_tickets.find(params[:id])
          render json: ticket, serializer: TicketSerializer
        end

        def create
          ticket = current_user_built_ticket
          if ticket.save
            render json: ticket, serializer: TicketSerializer, status: :created
          else
            render json: { errors: ticket.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def current_user_built_ticket
          Ticket.new(ticket_params.merge(reporter: current_user))
        end

        def scoped_tickets
          if current_user.role == 'landlord'
            Ticket.joins(room: :property).where(properties: { user_id: current_user.id })
          else
            Ticket.where(reporter: current_user)
          end
        end

        def ticket_params
          params.require(:ticket).permit(:room_id, :title, :description, :priority)
        end
      end
    end
  end
end
