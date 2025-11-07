module LaserBlob
  class Blob::Image < Blob
    validates :content_type, presence: true, format: /\Aimage\/\w+\Z/

    def width
      metadata['width']
    end

    def height
      metadata['height']
    end

    def dominant_color
      metadata['dominant_color']
    end

    def background_color
      metadata['background_color']
    end

    def aspect_ratio
      return nil unless self.width && self.height
      self.width.to_f / self.height.to_f
    end

    def self.process(record, path)
      require 'vips' unless defined?(Vips)

      vips = Vips::Image.new_from_file(path)
      record.metadata = {
        'width' =>      vips.width,
        'height' =>     vips.height,
        'dominant_color' => vips.thumbnail_image(1).getpoint(0, 0).join(","),
        'background_color' => vips.getpoint(0,0).join(",")
      }
    end
  end
end
