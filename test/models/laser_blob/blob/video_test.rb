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

end
