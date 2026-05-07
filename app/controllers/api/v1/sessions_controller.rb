module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_user!, only: %i[create]
      before_action :check_login_rate_limit!, only: %i[create]

      def create
        user = User.find_by(email: params[:email]&.downcase)

        if user&.authenticate(params[:password])
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token, user: UserSerializer.new(user).attributes }, status: :ok
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      def destroy
        # JWT is stateless — client must discard the token
        render json: { message: 'Signed out successfully' }, status: :ok
      end

      private

      def check_login_rate_limit!
        return unless login_rate_limit_exceeded?

        render json: { error: 'Too many requests. Please try again later.' },
               status: :too_many_requests
      rescue StandardError => e
        Rails.logger.error("[rate_limit] #{e.class}: #{e.message}")
      end

      def login_rate_limit_exceeded?
        rate_limit_keys.any? { |key| rate_limit_exceeded?(key) }
      end

      def rate_limit_exceeded?(key)
        Sidekiq.redis do |conn|
          count = conn.call('INCR', key)
          conn.call('EXPIRE', key, 60) if count == 1
          count > 5
        end
      end

      def rate_limit_keys
        keys = ["rate_limit:login:ip:#{request.ip}"]
        email_val = params[:email]&.downcase&.gsub(/\s+/, '')
        keys << "rate_limit:login:email:#{email_val}" if email_val.present?
        keys
      end
    end
  end
end
