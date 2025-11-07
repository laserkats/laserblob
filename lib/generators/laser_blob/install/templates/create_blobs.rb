class CreateBlobs < ActiveRecord::Migration[6.1]
  def change
    create_table :blobs, id: :uuid do |t|
      t.string :type, default: 'LaserBlob::Blob'
      t.bigint :size, null: false
      t.string :content_type, null: false
      t.jsonb :metadata, default: {}
      t.binary :sha1, limit: 20, null: false

      t.timestamps
    end

    add_index :blobs, :sha1
    add_index :blobs, [:type, :sha1]
  end
end
