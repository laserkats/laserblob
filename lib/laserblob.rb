require "laser_blob/version"
require "laser_blob/engine"
require "laser_blob/blob_helpers"
require "laser_blob/storage/filesystem"
require "laser_blob/storage/s3"
require "laser_blob/model_extensions"

# Require models explicitly since they're in a gem
require_relative "../app/models/laser_blob/blob"
require_relative "../app/models/laser_blob/attachment"
require_relative "../app/models/laser_blob/blob/image"
require_relative "../app/models/laser_blob/blob/video"
require_relative "../app/models/laser_blob/blob/pdf"

module LaserBlob
  mattr_accessor :storage_config

  class << self
    def configure
      yield self if block_given?
    end

    def storage
      @storage ||= begin
        config = storage_config || default_storage_config
        case config[:storage]
        when 'filesystem', nil
          LaserBlob::Storage::Filesystem.new(config)
        when 's3'
          LaserBlob::Storage::S3.new(config)
        else
          raise "Unknown storage type: #{config[:storage]}"
        end
      end
    end

    private

    def default_storage_config
      {
        storage: 'filesystem',
        path: Rails.root.join('storage', 'blobs')
      }
    end
  end
end
