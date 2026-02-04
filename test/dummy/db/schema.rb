ActiveRecord::Schema.define(version: 1) do
  create_table :blobs, id: :string, force: true do |t|
    t.string :type, default: 'LaserBlob::Blob'
    t.bigint :size, null: false
    t.string :content_type, null: false
    t.text :metadata, default: '{}'
    t.binary :sha1, limit: 20, null: false

    t.timestamps
  end

  add_index :blobs, :sha1
  add_index :blobs, [:type, :sha1]

  create_table :attachments, id: :string, force: true do |t|
    t.string :type
    t.integer :order, default: 0
    t.string :filename
    t.string :record_type, null: false
    t.string :record_id, null: false
    t.string :blob_id, null: false

    t.timestamps
  end

  add_index :attachments, [:record_type, :record_id]
  add_index :attachments, :blob_id

  # Sample model for testing has_blob associations
  create_table :documents, id: :string, force: true do |t|
    t.string :name
    t.timestamps
  end
end
