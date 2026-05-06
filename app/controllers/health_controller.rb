class HealthController < ApplicationController
  skip_before_action :authenticate_request, raise: false

  def show
    render json: {
      status:    "ok",
      env:       Rails.env,
      timestamp: Time.current.iso8601,
      db:        db_alive?,
      version:   ENV.fetch("RAILWAY_GIT_COMMIT_SHA", "local")[0, 7]
    }, status: :ok
  rescue StandardError => e
    render json: { status: "error", message: e.message }, status: :service_unavailable
  end

  private

  def db_alive?
    ActiveRecord::Base.connection.execute("SELECT 1")
    true
  rescue StandardError
    false
  end
end
