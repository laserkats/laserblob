module LaserBlob
  class Blob < ActiveRecord::Base
    self.table_name = 'blobs'

    include LaserBlob::BlobHelpers

    attr_reader :data

    has_many :attachments, class_name: 'LaserBlob::Attachment', dependent: :destroy
    validates :file, presence: true, on: :create
    validates :url, format: { with: URI::regexp(%w(http https)) }, on: :create, if: ->(b) { b.url }
    validates :content_type, presence: true
    validates :sha1, presence: true, length: { is: 20 }
    validates :size, numericality: { only_integer: true, greater_than: 0 }

    after_save    :store_file
    after_destroy :delete_file

    def self.new(attrs={})
      if attrs[:url] && attrs[:url] =~ URI::regexp(%w(http https))
        attrs[:file] = download_url(attrs.delete(:url))
      end

      if attrs[:base64]
        attrs[:file] = base64_file(attrs.delete(:base64), attrs)
      end

      if attrs[:data]
        attrs[:file] = data_file(attrs.delete(:data), attrs)
      end

      if attrs[:file]
        klass = attrs[:content_type] ? content_type_class(attrs[:content_type]) : file_class(attrs[:file])
        sha1 = file_sha1(attrs[:file])
        klass.find_by_sha1(sha1) || (klass == self ? super(attrs) : klass.new(attrs))
      else
        super(attrs)
      end
    end

    def url=(value)
      @url = value if !persisted?
    end

    def url(**options)
      options[:disposition] = options[:disposition] == 'inline' ? 'inline' : 'attachment'
      if options[:filename]
        options[:disposition] += "; filename=\"#{URI.encode_www_form_component(options[:filename].force_encoding(Encoding::UTF_8)).gsub("%2F", "/")}\""
      end

      if persisted?
        if self.class.storage.local?
          self.class.storage.url(id)
        else
          self.class.storage.url(id, **options.slice(:disposition, :expires_in))
        end
      else
        @url
      end
    end

    def file
      @queued
    end

    def data=(value)
      raise 'Cannot set file on persisted blob or blob with file already set' if persisted? || @file
      self.size = value.bytesize
      self.sha1 = Digest::SHA1.digest(value)

      @queued = Tempfile.new(binmode: true)
      @queued.write(value)
      @queued.flush
      @queued.rewind
    end

    def extension
      "." + MiniMime.lookup_by_content_type(content_type).extension
    end

    def file=(file)
      raise 'Cannot set file on persisted blob or blob with file already set' if persisted? || @file
      return if file.nil?

      if self.content_type.nil? || self.content_type == 'application/octet-stream'
        self.content_type = file_content_type(file)
      end
      self.size = file.size
      self.sha1 = file_sha1(file)

      @queued = Tempfile.new(binmode: true)
      FileUtils.cp(file.path, @queued.path)
    end

    def open(basename: nil, &block)
      basename ||= ['', extension]
      self.class.storage.copy_to_tempfile(id, basename: basename, &block)
    end

    private

    def store_file
      if @queued
        self.class.storage.write(id, @queued, { content_type: content_type })
      end
    ensure
      if @queued
        @queued.close
        if @queued.is_a? ActionDispatch::Http::UploadedFile
          @queued.tempfile.unlink
        else
          @queued.unlink
        end
        @queued = nil
      end
    end

    def delete_file
      self.class.storage.delete(id)
    end
  end
end
