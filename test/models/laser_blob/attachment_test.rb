require 'test_helper'

class LaserBlob::AttachmentTest < ActiveSupport::TestCase

  # has_blobs
  test 'has_blobs creating then submitting via nested_attributes' do
    image = create(:image)
    document = create(:document)

    assert document.update(attachments_attributes: [{ filename: 'test.png', blob_id: image.id }])
    assert_equal [image.id], document.attachments.map(&:blob_id)
  end

  test 'has_blobs attaching additional blob once already attached' do
    image1 = create(:image)
    image2 = create(:image)
    document = create(:document, attachments: [LaserBlob::Attachment.new(blob: image1, filename: 'test1.png')])

    document.update(attachments_attributes: [
      { blob_id: image1.id, filename: 'test1.png' },
      { blob_id: image2.id, filename: 'test2.png' }
    ])
    assert_equal 2, document.attachments.count
  end

  test 'has_blobs using nested_attributes replaces set attachments' do
    image1 = create(:image)
    image2 = create(:image)
    document = create(:document, attachments: [LaserBlob::Attachment.new(blob: image1, filename: 'test.png')])
    document.update!(attachments_attributes: [{ blob_id: image2.id, filename: 'test.png' }])
    assert_equal [image2.id], document.attachments.map(&:blob_id)
  end

  # has_blob
  test 'has_blob creating then submitting via nested_attributes' do
    image = create(:image)
    document = create(:document)

    assert document.update(file_attributes: { filename: 'test.png', blob_id: image.id })
    assert_equal image.id, document.file.blob_id
  end

  test 'has_blob replacing attached blob' do
    image1 = create(:image)
    image2 = create(:image)
    document = create(:document, file: LaserBlob::Attachment.new(blob: image1, filename: 'test.png'))

    document.update(file_attributes: { blob_id: image2.id, filename: 'test2.png' })
    assert_equal image2.id, document.file.blob_id
  end

end
