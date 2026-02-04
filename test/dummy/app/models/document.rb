class Document < ApplicationRecord
  include LaserBlob::ModelExtensions

  has_one_blob :file
  has_many_blobs :attachments
end

class ImageDocument < ApplicationRecord
  self.table_name = 'documents'

  include LaserBlob::ModelExtensions

  has_one_blob :cover, only: [:image]
  has_many_blobs :photos, only: [LaserBlob::Blob::Image]
end
