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
        ip_key    = "rate_limit:login:ip:#{request.ip}"
        email_val = params[:email]&.downcase&.gsub(/\s+/, '')
        keys      = [ip_key]
        keys << "rate_limit:login:email:#{email_val}" if email_val.present?

        keys.each do |key|
          exceeded = Sidekiq.redis do |conn|
            count = conn.call('INCR', key)
            conn.call('EXPIRE', key, 60) if count == 1
            count > 5
          end

          if exceeded
            render json: { error: 'Too many requests. Please try again later.' },
                   status: :too_many_requests
            return
          end
        end
      rescue StandardError => e
        Rails.logger.error("[rate_limit] #{e.class}: #{e.message}")
      end
    end
  end
end
