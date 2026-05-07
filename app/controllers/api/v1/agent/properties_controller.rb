module Api
  module V1
    module Agent
      class PropertiesController < BaseController
        def summary
          if current_user.role == 'landlord'
            render json: landlord_summary
          else
            render json: { error: 'Landlord only' }, status: :forbidden
          end
        end

        private

        def landlord_summary
          properties = current_user.properties.includes(rooms: :leases)
          properties.map do |p|
            {
              id: p.id,
              name: p.name,
              address: p.address,
              rooms_count: p.rooms.size,
              monthly_revenue: p.rooms.sum { |r| r.leases.where(status: 'active').sum(:monthly_rent) }
            }
          end
        end
      end
    end
  end
end
