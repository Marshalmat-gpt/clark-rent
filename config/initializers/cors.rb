Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    cors_origins = if Rails.env.production?
      ENV.fetch('CORS_ORIGINS').split(',').map(&:strip)
    else
      ENV.fetch('CORS_ORIGINS', 'http://localhost:3000').split(',').map(&:strip)
    end

    origins(cors_origins.size == 1 ? cors_origins.first : cors_origins)

    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             expose: ['Authorization']
  end
end
