require 'active_support/concern'
require 'mini_mime'
require 'digest/sha1'
require 'base64'
require 'tempfile'
require 'net/http'
require 'uri'

module LaserBlob
  module BlobHelpers
    extend ActiveSupport::Concern

    def file_content_type(file)
      self.class.file_content_type(file)
    end

    def file_sha1(file)
      self.class.file_sha1(file)
    end

    def self.filename_from_file(file)
      fn = if file.respond_to?(:original_filename)
        file.original_filename || File.basename(file.path)
      else
        File.basename(file.path)
      end
      "#{File.basename(fn, File.extname(fn))}#{File.extname(fn)&.downcase}"
    end

    class_methods do
      def storage
        LaserBlob.storage
      end

      def file_sha1(file)
        if file.is_a?(ActionDispatch::Http::UploadedFile)
          if file.instance_variable_get(:@sha1)
            file.instance_variable_get(:@sha1)
          else
            digest = Digest::SHA1.file(file.path).digest
            file.instance_variable_set(:@sha1, digest)
            digest
          end
        else
          Digest::SHA1.file(file.path).digest
        end
      end

      def download_url(url, headers: {})
        return unless url =~ URI::regexp(%w(http https))
        uri = URI.parse(url)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")

        http.request_get(uri.request_uri, headers) do |resp|
          if resp.is_a?(Net::HTTPRedirection)
            return download_url(resp['location'])
          elsif resp.is_a?(Net::HTTPSuccess)
            tmpfile = Tempfile.new(binmode: true)
            digest = Digest::SHA1.new

            resp.read_body do |part|
              digest << part
              tmpfile.write(part)
            end
            tmpfile.flush
            tmpfile.rewind

            filename = if resp["content-disposition"] && resp["content_disposition"] =~ /filename=/
              File.basename(resp["content-disposition"].match(/filename=\"(.*)\"/)[1])
            else
              fn = File.basename(uri.path)
              fn = 'index' if fn == '/'
              mime_type = MiniMime.lookup_by_content_type(resp["content-type"])
              extension = (mime_type ? ".#{mime_type.extension}" : File.extname(fn))
              File.basename(uri.path, ".*") + extension
            end

            content_type = resp["content-type"]
            if !content_type.present?
              # Fallback to MiniMime if content-type header is missing
              content_type = MiniMime.lookup_by_filename(filename)&.content_type || 'application/octet-stream'
            end

            file = ActionDispatch::Http::UploadedFile.new({
              filename: filename,
              type: content_type,
              tempfile: tmpfile
            })
            file.instance_variable_set(:@sha1, digest.digest)
            return file
          else
            raise Net::HTTPError.new("HTTP #{resp.code} loading #{url}", resp)
          end
        end
      end

      def data_file(value, attrs = {})
        sha1 = Digest::SHA1.digest(value)
        tmpfile = Tempfile.new(binmode: true)
        tmpfile.write(value)
        tmpfile.flush
        tmpfile.rewind

        file = ActionDispatch::Http::UploadedFile.new({
          filename: attrs[:filename],
          type: attrs[:content_type],
          tempfile: tmpfile
        })
        file.instance_variable_set(:@sha1, sha1)
        file
      end

      def base64_file(value, attrs = {})
        value = Base64.decode64(value)
        sha1 = Digest::SHA1.digest(value)
        tmpfile = Tempfile.new(binmode: true)
        tmpfile.write(value)
        tmpfile.flush
        tmpfile.rewind

        file = ActionDispatch::Http::UploadedFile.new({
          filename: attrs[:filename],
          type: attrs[:content_type],
          tempfile: tmpfile
        })
        file.instance_variable_set(:@sha1, sha1)
        file
      end

      def file_content_type(file)
        content_type = if file.respond_to?(:content_type)
          file.content_type&.strip
        else
          'application/octet-stream'
        end

        if content_type == 'application/octet-stream'
          content_type = MiniMime.lookup_by_filename(file.path)&.content_type
        end

        content_type
      end

      def file_class(file)
        content_type_class(file_content_type(file))
      end

      def content_type_class(content_type)
        descendant = self.descendants.find do |descendant|
          descendant.validators_on(:content_type).find do |validator|
            case validator
            when ActiveModel::Validations::FormatValidator
              content_type =~ validator.options[:with]
            when ActiveModel::Validations::InclusionValidator
              validator.send(:delimiter).include?(content_type)
            end
          end
        end

        descendant || self
      end
    end
  end
end
