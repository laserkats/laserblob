# LaserBlob Configuration
LaserBlob.configure do |config|
  # Storage configuration
  # For filesystem storage (default):
  config.storage_config = {
    storage: 'filesystem',
    path: Rails.root.join('storage', 'blobs')
  }

  # For S3 storage:
  # config.storage_config = {
  #   storage: 's3',
  #   bucket: ENV['S3_BUCKET'],
  #   access_key_id: ENV['S3_ACCESS_KEY_ID'],
  #   secret_access_key: ENV['S3_SECRET_ACCESS_KEY'],
  #   region: ENV['S3_REGION'] || 'us-east-1',
  #   endpoint: ENV['S3_ENDPOINT'] # Optional, for S3-compatible services like DigitalOcean Spaces
  # }
end
