module LaserBlob
  class Blob::Video < Blob
    validates :content_type, presence: true, format: /\Avideo\/.*\Z/

    def width
      metadata['width']
    end

    def height
      metadata['height']
    end

    def duration
      metadata['duration']
    end

    def bitrate
      metadata['bitrate']
    end

    def codec
      metadata['codec']
    end

    def frame_rate
      metadata['frame_rate']
    end

    def self.process(record, path)
      require 'streamio-ffmpeg' unless defined?(FFMPEG)

      video = FFMPEG::Movie.new(path)

      record.metadata = {
        'duration' =>   video.duration,
        'bitrate' =>    video.bitrate,
        'codec' =>      video.video_codec,
        'width' =>      video.width,
        'height' =>     video.height,
        'frame_rate' => video.frame_rate
      }
    end
  end
end
