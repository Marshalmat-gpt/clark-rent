# Initialise le client S3 global — disponible via Aws::S3::Client.new
# Les credentials viennent exclusivement des variables d'environnement.
Aws.config.update(
  region:      ENV.fetch('AWS_REGION',  'eu-west-3'),
  credentials: Aws::Credentials.new(
    ENV.fetch('AWS_ACCESS_KEY_ID'),
    ENV.fetch('AWS_SECRET_ACCESS_KEY')
  )
)

RAILS_S3_BUCKET = ENV.fetch('AWS_BUCKET', 'clark-rent-production')
