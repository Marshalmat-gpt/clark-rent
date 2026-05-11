Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end


# Load cron schedule on the Sidekiq server only. Avoid loading inside the
# Rails web process, the console, or RSpec — Sidekiq::Cron would otherwise
# try to talk to Redis at boot.
if Sidekiq.server? && !Rails.env.test?
  schedule_path = Rails.root.join('config/schedule.yml')
  if schedule_path.exist?
    require 'sidekiq-cron'
    Sidekiq::Cron::Job.load_from_hash!(YAML.load_file(schedule_path))
  end
end
