# SMTP via SendGrid en production. Le gem sendgrid-ruby reste disponible
# pour l'API HTTP si jamais on veut envoyer hors ActionMailer.
return unless Rails.env.production?
return if ENV['SENDGRID_API_KEY'].blank?

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  address: 'smtp.sendgrid.net',
  port: 587,
  domain: ENV.fetch('MAIL_DOMAIN', 'clarkrent.com'),
  user_name: 'apikey',
  password: ENV.fetch('SENDGRID_API_KEY'),
  authentication: :plain,
  enable_starttls_auto: true
}
ActionMailer::Base.default_url_options = { host: ENV.fetch('APP_HOST', 'api.clarkrent.com') }
