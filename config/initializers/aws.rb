require 'aws-sdk-s3'

# Configure le client S3 global uniquement quand les credentials sont
# présentes — laisse les tests CI tourner sans variables AWS.
if ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
  Aws.config.update(
    region: ENV.fetch('AWS_REGION', 'eu-west-3'),
    credentials: Aws::Credentials.new(
      ENV.fetch('AWS_ACCESS_KEY_ID'),
      ENV.fetch('AWS_SECRET_ACCESS_KEY')
    )
  )
end

RAILS_S3_BUCKET = ENV.fetch('AWS_BUCKET', 'clark-rent-production')
