module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    header = request.headers['Authorization']
    token  = header&.split(' ')&.last
    raise JWT::DecodeError, 'Missing token' if token.nil?

    decoded = JsonWebToken.decode(token)
    @current_user = User.find(decoded[:user_id])
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def current_user
    @current_user
  end
end
