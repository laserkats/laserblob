require 'test_helper'

class LaserBlob::Blob::PDFTest < ActiveSupport::TestCase

  test 'pdf type is assigned for pdf content type' do
    blob = LaserBlob::Blob.new(data: 'fake pdf', content_type: 'application/pdf')
    assert_equal LaserBlob::Blob::PDF, blob.class
  end

  test 'pdf validates content_type' do
    blob = LaserBlob::Blob::PDF.new(data: 'test', content_type: 'text/plain')
    blob.size = 4
    blob.sha1 = Digest::SHA1.digest('test')
    assert_not blob.valid?
    assert blob.errors[:content_type].present?
  end

  test 'page_count accessor' do
    blob = LaserBlob::Blob::PDF.new
    blob.metadata = { 'pages' => [{ 'width' => 612, 'height' => 792 }] * 5 }

    assert_equal 5, blob.page_count
  end

  test 'process! extracts pdf metadata' do
    begin
      require 'pdf-reader'
    rescue LoadError
      skip "Requires pdf-reader gem"
    end

    pdf = create(:pdf)
    pdf.process!

    assert_equal 1, pdf.page_count
    assert_equal 612.0, pdf.metadata['pages'].first['width']
    assert_equal 792.0, pdf.metadata['pages'].first['height']
    assert_in_delta 0.7727, pdf.aspect_ratio, 0.001
  end

end
