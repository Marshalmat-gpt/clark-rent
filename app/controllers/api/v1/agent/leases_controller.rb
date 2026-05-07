module Api
  module V1
    module Agent
      class LeasesController < BaseController
        def irl
          lease = scoped_leases.find(params[:id])
          base  = params.require(:base_irl).to_f
          curr  = params.require(:current_irl).to_f

          result = ClarkAgent::IrlCalculator.new(
            reference_rent: lease.monthly_rent,
            base_irl: base,
            current_irl: curr
          ).call
          render json: result
        rescue ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :bad_request
        rescue ArgumentError => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        private

        def scoped_leases
          if current_user.role == 'landlord'
            Lease.joins(room: :property).where(properties: { user_id: current_user.id })
          else
            current_user.leases
          end
        end
      end
    end
  end
end
