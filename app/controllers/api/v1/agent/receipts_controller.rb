module Api
  module V1
    module Agent
      class ReceiptsController < BaseController
        def create
          lease  = scoped_leases.find(params.require(:lease_id))
          period = params[:period].present? ? Date.parse(params[:period]) : Date.current

          io  = ClarkAgent::ReceiptPdf.new(lease: lease, period: period).render
          key = "receipts/#{lease.id}/#{period.strftime('%Y-%m')}.pdf"

          if defined?(S3Service) && ENV['AWS_ACCESS_KEY_ID']
            S3Service.upload(file: io, key: key, content_type: 'application/pdf')
            render json: { key: key, url: S3Service.presigned_url(key) }
          else
            render json: { key: key, size_bytes: io.size, persisted: false }
          end
        rescue ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :bad_request
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
