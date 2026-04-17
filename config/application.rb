require_relative 'boot'
require 'rails'
require 'active_record/railtie'
require 'active_model/railtie'
require 'action_controller/railtie'
require 'active_job/railtie'
Bundler.require(*Rails.groups)
module ClarkRent
  class Application < Rails::Application
    config.load_defaults 7.2
    config.api_only = true
    config.time_zone = 'Paris'
    config.i18n.default_locale = :fr
    config.active_job.queue_adapter = :sidekiq
  end
end
