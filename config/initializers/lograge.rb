# Lograge condense les logs Rails en une ligne par requête, format JSON
# en production / staging et texte court en dev.
Rails.application.configure do
  config.lograge.enabled = !Rails.env.test?
  config.lograge.base_controller_class = 'ActionController::API'
  config.lograge.formatter = if Rails.env.development?
                               Lograge::Formatters::KeyValue.new
                             else
                               Lograge::Formatters::Json.new
                             end

  # Champs additionnels — request_id (Heroku/Railway), user_id si auth
  config.lograge.custom_options = lambda do |event|
    {
      time: event.time.iso8601,
      request_id: event.payload[:headers]&.[]('action_dispatch.request_id'),
      user_id: event.payload[:user_id],
      params: event.payload[:params]&.except('controller', 'action', 'format', 'id')
    }.compact
  end
end
