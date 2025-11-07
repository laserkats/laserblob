require 'aws-sdk-s3'

module LaserBlob
  module Storage
    class S3
      attr_reader :bucket, :client

      def initialize(config = {})
        @bucket = config[:bucket]
        @client = Aws::S3::Client.new(
          access_key_id: config[:access_key_id],
          secret_access_key: config[:secret_access_key],
          region: config[:region] || 'us-east-1',
          endpoint: config[:endpoint]
        )
        @resource = Aws::S3::Resource.new(client: @client)
        @bucket_obj = @resource.bucket(@bucket)
      end

      def local?
        false
      end

      def write(id, file, options = {})
        @bucket_obj.object(key_for(id)).upload_file(
          file.path,
          content_type: options[:content_type]
        )
      end

      def read(id)
        @bucket_obj.object(key_for(id)).get.body.read
      end

      def delete(id)
        @bucket_obj.object(key_for(id)).delete
      end

      def exists?(id)
        @bucket_obj.object(key_for(id)).exists?
      end

      def url(id, disposition: 'attachment', expires_in: 300)
        @bucket_obj.object(key_for(id)).presigned_url(
          :get,
          expires_in: expires_in,
          response_content_disposition: disposition
        )
      end

      def copy_to_tempfile(id, basename: nil, &block)
        basename ||= ['blob', '']

        Tempfile.create(basename, binmode: true) do |tmpfile|
          @bucket_obj.object(key_for(id)).get(response_target: tmpfile.path)
          tmpfile.rewind
          block.call(tmpfile)
        end
      end

      private

      def key_for(id)
        "blobs/#{id}"
      end
    end
  end
end
