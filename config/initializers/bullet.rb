# Bullet — N+1 + unused eager-loading detector.
# Active in development and test only. Logs to log/bullet.log; the
# rails logger surfaces warnings inline so devs can act on them.
#
# We intentionally do NOT raise in tests — many existing controllers
# return small per-request collections where Bullet's heuristic
# triggers false positives. Treat the log as advisory until each
# warning is addressed.
return unless defined?(Bullet)
return unless Rails.env.development? || Rails.env.test?

Bullet.enable        = true
Bullet.bullet_logger = true
Bullet.rails_logger  = true
Bullet.raise         = false
Bullet.alert         = false
Bullet.console       = Rails.env.development?
