class HealthController < ApplicationController
  skip_before_action :authenticate_request, raise: false

  # GET /health
  # Returns 200 with subsystem booleans + Sidekiq queue stats.
  # Returns 503 when the database is unreachable (Railway healthcheck signal).
  def show
    db    = db_alive?
    redis = redis_alive?
    sidekiq_stats = sidekiq_summary

    body = {
      status: db ? 'ok' : 'error',
      env: Rails.env,
      timestamp: Time.current.iso8601,
      version: ENV.fetch('RAILWAY_GIT_COMMIT_SHA', 'local')[0, 7],
      db: db,
      redis: redis,
      sidekiq: sidekiq_stats
    }

    render json: body, status: (db ? :ok : :service_unavailable)
  rescue StandardError => e
    render json: { status: 'error', message: e.message }, status: :service_unavailable
  end

  private

  def db_alive?
    ActiveRecord::Base.connection.execute('SELECT 1')
    true
  rescue StandardError
    false
  end

  def redis_alive?
    return false unless defined?(Sidekiq)

    Sidekiq.redis { |c| c.call('PING') } == 'PONG'
  rescue StandardError
    false
  end

  def sidekiq_summary
    return { available: false } unless defined?(Sidekiq::Stats)

    stats = Sidekiq::Stats.new
    {
      available: true,
      enqueued: stats.enqueued,
      busy: stats.workers_size,
      retry: stats.retry_size,
      dead: stats.dead_size
    }
  rescue StandardError
    { available: false }
  end
end
