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
end
