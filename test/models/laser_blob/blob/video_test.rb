require 'test_helper'

class LaserBlob::Blob::VideoTest < ActiveSupport::TestCase

  test 'video type is assigned for video content types' do
    %w[video/mp4 video/quicktime video/webm].each do |content_type|
      blob = LaserBlob::Blob.new(data: 'fake video', content_type: content_type)
      assert_equal LaserBlob::Blob::Video, blob.class, "Expected Video for #{content_type}"
    end
  end

  test 'video validates content_type' do
    blob = LaserBlob::Blob::Video.new(data: 'test', content_type: 'text/plain')
    blob.size = 4
    blob.sha1 = Digest::SHA1.digest('test')
    assert_not blob.valid?
    assert blob.errors[:content_type].present?
  end

  test 'width, height, duration, bitrate, codec, frame_rate accessors' do
    blob = LaserBlob::Blob::Video.new
    blob.metadata = {
      'width' => 1920,
      'height' => 1080,
      'duration' => 120.5,
      'bitrate' => 5000,
      'codec' => 'h264',
      'frame_rate' => 30.0
    }

    assert_equal 1920, blob.width
    assert_equal 1080, blob.height
    assert_equal 120.5, blob.duration
    assert_equal 5000, blob.bitrate
    assert_equal 'h264', blob.codec
    assert_equal 30.0, blob.frame_rate
  end

  test 'process! extracts video metadata' do
    begin
      require 'streamio-ffmpeg'
    rescue LoadError
      skip "Requires streamio-ffmpeg gem"
    end

    video = create(:video)
    video.process!

    assert_equal 320, video.width
    assert_equal 240, video.height
    assert_in_delta 1.0, video.duration, 0.1
    assert_equal 'h264', video.codec
  end

end
