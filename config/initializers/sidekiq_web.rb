# Sidekiq::Web is mounted at /admin/sidekiq in config/routes.rb.
#
# Rails runs in API mode (no cookie/session middleware). Disable the
# default session here so the dashboard works behind Rack::Auth::Basic
# without forcing a session store.
require 'sidekiq/web'
Sidekiq::Web.set :sessions, false
