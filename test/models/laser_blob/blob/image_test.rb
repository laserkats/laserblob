require 'test_helper'

class LaserBlob::Blob::ImageTest < ActiveSupport::TestCase

  test 'image type is assigned for image content types' do
    %w[image/png image/jpeg image/gif image/webp].each do |content_type|
      blob = LaserBlob::Blob.new(data: 'fake image', content_type: content_type)
      assert_equal LaserBlob::Blob::Image, blob.class, "Expected Image for #{content_type}"
    end
  end

  test 'image validates content_type' do
    blob = LaserBlob::Blob::Image.new(data: 'test', content_type: 'text/plain')
    blob.size = 4
    blob.sha1 = Digest::SHA1.digest('test')
    assert_not blob.valid?
    assert blob.errors[:content_type].present?
  end

  test 'process! extracts image metadata' do
    begin
      require 'vips'
    rescue LoadError
      skip "Requires ruby-vips"
    end

    image = create(:image)
    image.process!

    assert_equal 1, image.width
    assert_equal 1, image.height
    assert image.dominant_color.present?
    assert image.background_color.present?
  end

  test 'width and height accessors' do
    blob = LaserBlob::Blob::Image.new
    blob.metadata = { 'width' => 800, 'height' => 600 }

    assert_equal 800, blob.width
    assert_equal 600, blob.height
  end

end
