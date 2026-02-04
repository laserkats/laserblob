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

  # has_one_blob with only: option
  test 'has_one_blob only: accepts allowed blob type' do
    image = create(:image)
    doc = ImageDocument.new(name: 'Test')
    doc.cover = LaserBlob::Attachment.new(blob: image, filename: 'cover.png')

    assert doc.valid?
    assert doc.save
  end

  test 'has_one_blob only: rejects disallowed blob type' do
    pdf = create(:pdf)
    doc = ImageDocument.new(name: 'Test')
    doc.cover = LaserBlob::Attachment.new(blob: pdf, filename: 'cover.pdf')

    assert_not doc.valid?
    assert doc.errors[:cover].any? { |e| e.include?('invalid blob type') }
    assert doc.errors[:cover].any? { |e| e.include?('image') }
  end

  # has_many_blobs with only: option
  test 'has_many_blobs only: accepts allowed blob types' do
    image1 = create(:image)
    image2 = create(:image)
    doc = ImageDocument.new(name: 'Test')
    doc.photos = [
      LaserBlob::Attachment.new(blob: image1, filename: 'photo1.png'),
      LaserBlob::Attachment.new(blob: image2, filename: 'photo2.png')
    ]

    assert doc.valid?
    assert doc.save
    assert_equal 2, doc.photos.count
  end

  test 'has_many_blobs only: rejects disallowed blob type' do
    image = create(:image)
    pdf = create(:pdf)
    doc = ImageDocument.new(name: 'Test')
    doc.photos = [
      LaserBlob::Attachment.new(blob: image, filename: 'photo.png'),
      LaserBlob::Attachment.new(blob: pdf, filename: 'doc.pdf')
    ]

    assert_not doc.valid?
    assert doc.errors[:photos].any? { |e| e.include?('invalid blob type') }
  end

  test 'has_many_blobs only: rejects all disallowed blob types' do
    pdf1 = create(:pdf)
    pdf2 = create(:pdf)
    doc = ImageDocument.new(name: 'Test')
    doc.photos = [
      LaserBlob::Attachment.new(blob: pdf1, filename: 'doc1.pdf'),
      LaserBlob::Attachment.new(blob: pdf2, filename: 'doc2.pdf')
    ]

    assert_not doc.valid?
    assert doc.errors[:photos].present?
  end

end
