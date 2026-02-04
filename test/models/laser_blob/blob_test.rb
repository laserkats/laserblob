require 'test_helper'

class LaserBlob::BlobTest < ActiveSupport::TestCase

  test 'presence of size' do
    blob = build(:blob)
    blob.size = nil
    assert_not blob.valid?
    assert blob.errors[:size].present?
  end

  test 'presence of content_type' do
    blob = build(:blob)
    blob.content_type = nil
    assert_not blob.valid?
    assert blob.errors[:content_type].present?
  end

  test 'presence of file on create' do
    blob = LaserBlob::Blob.new
    assert_not blob.valid?
    assert blob.errors[:file].present?
  end

  test 'creating from url' do
    stub_request(:get, "https://example.com/image.png").to_return(
      body: "fake image data",
      headers: { 'Content-Type' => "image/png" }
    )

    blob = LaserBlob::Blob.create(url: 'https://example.com/image.png')
    assert blob.persisted?
    assert_equal 'LaserBlob::Blob::Image', blob.type
    assert_equal 'image/png', blob.content_type
  end

  test 'creating from data' do
    blob = LaserBlob::Blob.create!(data: 'hello world', content_type: 'text/plain')
    assert blob.persisted?
    assert_equal 'text/plain', blob.content_type
    assert_equal "2aae6c35c94fcfb415dbe95f408b9ce91ee846ed", blob.sha1.unpack1('H*')
  end

  test 'creating from invalid url' do
    blob = LaserBlob::Blob.new(url: 'not-a-url')
    assert_not blob.valid?
    assert blob.errors[:url].present?
  end

  test 'uploading with octet-stream content_type guesses mime-type from extension' do
    Tempfile.create(['test', '.xlsx'], binmode: true) do |file|
      file.write(SecureRandom.random_bytes(100))
      file.flush
      blob = LaserBlob::Blob.create!(file: Rack::Test::UploadedFile.new(file.path, 'application/octet-stream'))

      assert_equal 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', blob.content_type
    end
  end

  test '::new returns existing blob if duplicate sha1' do
    existing_blob = LaserBlob::Blob.create!(data: 'hello world', content_type: 'text/plain')
    new_blob = LaserBlob::Blob.new(data: 'hello world', content_type: 'text/plain')
    assert_equal existing_blob.id, new_blob.id
  end

  test '::create returns existing blob if duplicate sha1' do
    existing_blob = LaserBlob::Blob.create!(data: 'hello world', content_type: 'text/plain')
    new_blob = LaserBlob::Blob.create(data: 'hello world', content_type: 'text/plain')
    assert_equal existing_blob.id, new_blob.id
  end

  test '::new assigns correct type based on content_type' do
    blob = LaserBlob::Blob.new(data: 'test', content_type: 'image/png')
    assert_equal LaserBlob::Blob::Image, blob.class

    blob = LaserBlob::Blob.new(data: 'test', content_type: 'video/mp4')
    assert_equal LaserBlob::Blob::Video, blob.class

    blob = LaserBlob::Blob.new(data: 'test', content_type: 'application/pdf')
    assert_equal LaserBlob::Blob::PDF, blob.class

    blob = LaserBlob::Blob.new(data: 'plain text', content_type: 'text/plain')
    assert_equal LaserBlob::Blob, blob.class
  end

  test '::new with explicit content_type uses that type' do
    stub_request(:get, "https://example.com/image").to_return(
      body: "fake data",
      headers: { 'Content-Type' => "" }
    )
    blob = LaserBlob::Blob.new(url: 'https://example.com/image', content_type: 'image/png')
    assert_equal LaserBlob::Blob::Image, blob.class
  end

  test 'blob is destroyed with its file' do
    blob = LaserBlob::Blob.create!(data: 'test content', content_type: 'text/plain')
    blob_id = blob.id

    assert LaserBlob::Blob.storage.exists?(blob_id)

    blob.destroy

    assert_not LaserBlob::Blob.storage.exists?(blob_id)
  end

end
