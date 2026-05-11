module Api
  module V1
    module Agent
      class DocumentsController < BaseController
        ALLOWED = %w[lease receipt application].freeze

        def show
          type = params[:type]
          return render json: { error: 'Unknown type' }, status: :bad_request unless ALLOWED.include?(type)

          # Key is always derived from current_user — raw S3 keys are never accepted from the client
          lease = current_user.active_lease
          return render json: { error: 'No active lease found' }, status: :not_found unless lease

          attachment = case type
                       when 'lease'       then lease.document
                       when 'receipt'     then lease.rent_payments.order(paid_at: :desc).first&.receipt
                       when 'application' then nil
                       end

          return render json: { error: 'Document not found or not yet generated' }, status: :not_found unless attachment&.attached?

          render json: { url: attachment.blob.service_url(expires_in: 1.hour) }
        rescue ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :bad_request
        end
      end
    end
  end
end
