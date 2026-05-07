# Sentry — capture des exceptions et performance (production seulement,
# inactif sans SENTRY_DSN). Le gem se met en place silencieusement quand
# la DSN est vide.
return if ENV['SENTRY_DSN'].blank?

Sentry.init do |config|
  config.dsn = ENV.fetch('SENTRY_DSN')
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.environment        = ENV.fetch('SENTRY_ENVIRONMENT', Rails.env)
  config.release            = ENV['RAILWAY_GIT_COMMIT_SHA']
  config.send_default_pii   = false

  # Échantillonnage performance — 10% par défaut, surchargeable.
  config.traces_sample_rate = ENV.fetch('SENTRY_TRACES_SAMPLE_RATE', '0.1').to_f

  # Exclure les exceptions attendues (404, validation, etc.).
  config.excluded_exceptions += %w[
    ActiveRecord::RecordNotFound
    ActionController::ParameterMissing
    ActionController::RoutingError
  ]
end
