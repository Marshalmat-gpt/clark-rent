# Bullet — N+1 + unused eager-loading + missing counter-cache detector.
# Active in development and test only; loud in dev, raises in test so
# CI fails fast on regressions.
return unless defined?(Bullet)
return unless Rails.env.development? || Rails.env.test?

Bullet.enable        = true
Bullet.bullet_logger = true   # log to log/bullet.log
Bullet.rails_logger  = true   # also tag the request log

if Rails.env.test?
  Bullet.raise = true         # fail specs that surface a Bullet warning
else
  Bullet.alert  = false       # API only -> no JS alert
  Bullet.console = true       # window.console.log on each N+1
end
