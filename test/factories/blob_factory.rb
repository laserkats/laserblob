FactoryBot.define do
  factory :blob, class: 'LaserBlob::Blob' do
    transient do
      random_content { SecureRandom.random_bytes(100) }
    end

    file do
      f = Tempfile.new(['blob', '.bin'], binmode: true)
      f.write(random_content)
      f.flush
      f.rewind
      Rack::Test::UploadedFile.new(f.path, 'application/octet-stream', true)
    end
  end

  factory :image, class: 'LaserBlob::Blob::Image' do
    file do
      Rack::Test::UploadedFile.new(FIXTURES.join('test.png'), 'image/png', true)
    end
  end

  factory :png, parent: :image

  factory :video, class: 'LaserBlob::Blob::Video' do
    file do
      Rack::Test::UploadedFile.new(FIXTURES.join('test.mp4'), 'video/mp4', true)
    end
  end

  factory :pdf, class: 'LaserBlob::Blob::PDF' do
    file do
      Rack::Test::UploadedFile.new(FIXTURES.join('test.pdf'), 'application/pdf', true)
    end
  end

  factory :spreadsheet, class: 'LaserBlob::Blob::Spreadsheet' do
    file do
      f = Tempfile.new(['spreadsheet', '.csv'], binmode: true)
      f.write("col1,col2,col3\nval1,val2,val3\n")
      f.flush
      Rack::Test::UploadedFile.new(f.path, 'text/csv', true)
    end
  end

  factory :xlsx, class: 'LaserBlob::Blob::Spreadsheet' do
    file do
      f = Tempfile.new(['spreadsheet', '.xlsx'], binmode: true)
      f.write(SecureRandom.random_bytes(100))
      f.flush
      Rack::Test::UploadedFile.new(f.path, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', true)
    end
  end

  factory :attachment, class: 'LaserBlob::Attachment' do
    association :blob
    filename { 'test.bin' }
    record { association :document }
  end

  factory :document do
    name { 'Test Document' }
  end
end
