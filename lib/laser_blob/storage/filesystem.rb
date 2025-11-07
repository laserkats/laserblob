require 'fileutils'

module LaserBlob
  module Storage
    class Filesystem
      attr_reader :path

      def initialize(config = {})
        @path = config[:path] || Rails.root.join('storage', 'blobs')
        FileUtils.mkdir_p(@path)
      end

      def local?
        true
      end

      def write(id, file, options = {})
        file_path = path_for(id)
        FileUtils.mkdir_p(File.dirname(file_path))
        FileUtils.cp(file.path, file_path)
      end

      def read(id)
        File.read(path_for(id))
      end

      def delete(id)
        FileUtils.rm_f(path_for(id))
      end

      def exists?(id)
        File.exist?(path_for(id))
      end

      def url(id, **options)
        "/blobs/#{id}/download"
      end

      def copy_to_tempfile(id, basename: nil, &block)
        basename ||= ['blob', '']
        source_path = path_for(id)

        Tempfile.create(basename, binmode: true) do |tmpfile|
          FileUtils.cp(source_path, tmpfile.path)
          tmpfile.rewind
          block.call(tmpfile)
        end
      end

      private

      def path_for(id)
        # Split ID into subdirectories for better filesystem performance
        # e.g., "abc123" -> "ab/c1/abc123"
        id_str = id.to_s
        File.join(@path, id_str[0..1], id_str[2..3], id_str)
      end
    end
  end
end
