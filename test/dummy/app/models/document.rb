class Document < ApplicationRecord
  include LaserBlob::ModelExtensions

  has_one_blob :file
  has_many_blobs :attachments
end
