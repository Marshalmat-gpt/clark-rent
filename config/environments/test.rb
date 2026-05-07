Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = false
  config.public_file_server.enabled = true
  config.consider_all_requests_local = true
  config.cache_store = :null_store
  config.active_support.deprecation = :stderr
  config.active_support.discard_errors_in_after_callbacks = false
  config.active_record.maintain_test_schema = true
  config.active_job.queue_adapter = :test

  # ActionMailer
  config.action_mailer.delivery_method = :test
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { host: 'test.clarkrent.com' }
end
