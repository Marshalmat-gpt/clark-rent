# Service d'abstraction S3 — utilisé par les controllers pour
# upload, génération d'URLs signées et suppression d'objets.
#
# Usage :
#   url = S3Service.presigned_url('documents/lease_42.pdf')
#   S3Service.upload(file: io, key: 'photos/room_1.jpg', content_type: 'image/jpeg')
#   S3Service.delete('documents/old_file.pdf')

class S3Service
  EXPIRY = 15.minutes

  class << self
    def client
      @client ||= Aws::S3::Client.new
    end

    def resource
      @resource ||= Aws::S3::Resource.new(client: client)
    end

    def bucket
      resource.bucket(RAILS_S3_BUCKET)
    end

    # Retourne une URL signée GET valable EXPIRY minutes
    def presigned_url(key, expires_in: EXPIRY)
      signer = Aws::S3::Presigner.new(client: client)
      signer.presigned_url(:get_object,
                           bucket: RAILS_S3_BUCKET,
                           key:    key,
                           expires_in: expires_in.to_i)
    end

    # Upload un IO object (File, StringIO, Tempfile)
    # Retourne le key S3 si succès, raise en cas d'erreur
    def upload(file:, key:, content_type: 'application/octet-stream', acl: 'private')
      client.put_object(
        bucket:       RAILS_S3_BUCKET,
        key:          key,
        body:         file,
        content_type: content_type,
        server_side_encryption: 'AES256'
      )
      key
    end

    # Supprime un objet S3 (idempotent)
    def delete(key)
      client.delete_object(bucket: RAILS_S3_BUCKET, key: key)
    end
  end
end
