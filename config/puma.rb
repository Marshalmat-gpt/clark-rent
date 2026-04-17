max_threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
min_threads_count = ENV.fetch('RAILS_MIN_THREADS') { max_threads_count }
threads min_threads_count, max_threads_count

rails_env = ENV.fetch('RAILS_ENV', 'development')
environment rails_env
port ENV.fetch('PORT', 3000)
pidfile ENV.fetch('PIDFILE', 'tmp/pids/server.pid')

# worker_timeout is a cluster-mode directive (no effect in single-mode dev),
# kept to document long-request tolerance during development debugging
worker_timeout 3600 if rails_env == 'development'

if rails_env == 'production'
  workers ENV.fetch('WEB_CONCURRENCY', 2)
  preload_app!
end

plugin :tmp_restart
