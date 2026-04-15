module Api
  module V1
    module Agent
      class AgentController < Api::V1::ApplicationController

        # POST /api/v1/agent/chat
        def chat
          message = params.require(:message)
          history = params[:history] || []

          system_prompt = ClarkAgent::SystemPrompt.build(
            user: current_user,
            role: current_role
          )

          result = ClarkAgent::Orchestrator.run(
            system:  system_prompt,
            history: history,
            message: message,
            user:    current_user,
            role:    current_role
          )

          render json: {
            reply:   result[:reply],
            actions: result[:actions],
            history: result[:history]
          }
        rescue => e
          Rails.logger.error "[ClarkAgent] Error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
          render json: { error: 'Une erreur est survenue' }, status: :internal_server_error
        end

        # GET /api/v1/agent/context
        def context
          if owner?
            properties = current_user.properties.includes(:leases)
            render json: {
              role:            'owner',
              name:            current_user.full_name,
              property_count:  properties.count,
              open_leases:     properties.flat_map(&:leases).count { |l| l.status == 'open' },
              open_tickets:    Ticket.for_owner(current_user).open.count
            }
          else
            lease = current_user.active_lease
            render json: {
              role:           'tenant',
              name:           current_user.full_name,
              lease_status:   lease&.status,
              address:        lease&.property&.formatted_address,
              rent:           lease&.amount,
              expenses:       lease&.expense_amount
            }
          end
        end

      end
    end
  end
end
