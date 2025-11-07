module LaserBlob
  class Blob::PDF < Blob
    validates :content_type, presence: true, format: /\Aapplication\/pdf\Z/

    def page_count
      metadata['pages']&.size || 0
    end

    def aspect_ratio
      first_page = metadata['pages']&.first
      return nil unless first_page

      width = first_page['width'].to_f
      height = first_page['height'].to_f

      return nil if height.zero?

      width / height
    end

    def self.process(record, path)
      require 'pdf-reader' unless defined?(PDF::Reader)

      record.metadata = {
        'pages' => PDF::Reader.new(path).pages.map { |page|
          { 'width' => page.width, 'height' => page.height }
        }
      }
    end
  end
end
