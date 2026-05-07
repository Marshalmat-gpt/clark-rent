module Api
  module V1
    module Agent
      class DocumentsController < BaseController
        ALLOWED = %w[lease receipt application].freeze

        def show
          type = params[:type]
          return render json: { error: 'Unknown type' }, status: :bad_request unless ALLOWED.include?(type)

          key = params.require(:key)
          if defined?(S3Service) && ENV['AWS_ACCESS_KEY_ID']
            render json: { url: S3Service.presigned_url(key) }
          else
            render json: { url: nil, key: key, persisted: false }
          end
        rescue ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :bad_request
        end
      end
    end
  end
end
