# LaserBlob

LaserBlob is a content-addressable blob storage system for Rails applications. It provides SHA1-based deduplication, polymorphic attachments, and support for multiple storage backends (filesystem and S3).

## Features

- **Content-addressable storage**: Blobs are identified by SHA1 hash, preventing duplicate storage
- **Polymorphic attachments**: Attach blobs to any model with `has_one_blob` or `has_many_blobs`
- **Multiple storage backends**: Filesystem or S3-compatible storage
- **Type-specific models**: Built-in support for images, videos, and PDFs with automatic metadata extraction
- **Flexible input**: Create blobs from files, URLs, base64 data, or raw data
- **URL generation**: Generate signed URLs for cloud storage or local paths

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'laserblob'
```

And then execute:

```bash
bundle install
```

Run the installer to generate migrations and configuration:

```bash
rails generate laserblob:install
rails db:migrate
```

## Configuration

Configure your storage backend in `config/initializers/laserblob.rb`:

### Filesystem Storage (Default)

```ruby
LaserBlob.configure do |config|
  config.storage_config = {
    storage: 'filesystem',
    path: Rails.root.join('storage', 'blobs')
  }
end
```

### S3 Storage

```ruby
LaserBlob.configure do |config|
  config.storage_config = {
    storage: 's3',
    bucket: ENV['S3_BUCKET'],
    access_key_id: ENV['S3_ACCESS_KEY_ID'],
    secret_access_key: ENV['S3_SECRET_ACCESS_KEY'],
    region: ENV['S3_REGION'] || 'us-east-1',
    endpoint: ENV['S3_ENDPOINT'] # Optional, for S3-compatible services
  }
end
```

## Usage

### Adding Attachments to Models

#### Single Attachment

```ruby
class User < ApplicationRecord
  has_one_blob :avatar
end

# Usage
user = User.new
user.avatar = params[:avatar]  # File upload
user.save
```

#### Multiple Attachments

```ruby
class Post < ApplicationRecord
  has_many_blobs :images
end

# Usage
post = Post.new
post.images = [file1, file2, file3]
post.save
```

### Creating Blobs

#### From File Upload

```ruby
blob = LaserBlob::Blob.new(file: params[:file])
blob.save
```

#### From URL

```ruby
blob = LaserBlob::Blob.new(url: "https://example.com/image.jpg")
blob.save
```

#### From Base64

```ruby
blob = LaserBlob::Blob.new(
  base64: base64_string,
  content_type: "image/png",
  filename: "image.png"
)
blob.save
```

#### From Raw Data

```ruby
blob = LaserBlob::Blob.new(data: binary_data)
blob.content_type = "image/jpeg"
blob.save
```

### Accessing Blobs

```ruby
# Get blob URL
user.avatar.url

# Get blob URL with options
blob.url(disposition: 'inline', filename: 'custom.jpg', expires_in: 3600)

# Get blob metadata
blob.size          # File size in bytes
blob.content_type  # MIME type
blob.sha1          # Binary SHA1 hash
blob.extension     # File extension based on content type

# Open blob for processing
blob.open do |file|
  # Process the file
  puts file.read
end
```

### Blob Types

LaserBlob automatically selects the appropriate blob type based on content type:

#### Images (LaserBlob::Blob::Image)

Requires `ruby-vips` gem:

```ruby
gem 'ruby-vips'
```

Automatically extracts:
- Width and height
- Dominant color
- Background color
- Aspect ratio

```ruby
image = LaserBlob::Blob.new(file: image_file)
image.save

image.width          # => 1920
image.height         # => 1080
image.aspect_ratio   # => 1.777...
image.dominant_color # => "255,128,0"
```

#### Videos (LaserBlob::Blob::Video)

Requires `streamio-ffmpeg` gem:

```ruby
gem 'streamio-ffmpeg'
```

Automatically extracts:
- Duration
- Bitrate
- Codec
- Width and height
- Frame rate

```ruby
video = LaserBlob::Blob.new(file: video_file)
video.save

video.duration    # => 120.5 (seconds)
video.width       # => 1920
video.height      # => 1080
video.codec       # => "h264"
video.frame_rate  # => 30.0
```

#### PDFs (LaserBlob::Blob::PDF)

Requires `pdf-reader` gem:

```ruby
gem 'pdf-reader'
```

Automatically extracts:
- Page count
- Width and height per page
- Aspect ratio

```ruby
pdf = LaserBlob::Blob.new(file: pdf_file)
pdf.save

pdf.page_count    # => 10
pdf.aspect_ratio  # => 0.707 (based on first page)
```

### Deduplication

LaserBlob automatically deduplicates blobs based on SHA1 hash:

```ruby
# Upload the same file twice
blob1 = LaserBlob::Blob.new(file: file)
blob1.save

blob2 = LaserBlob::Blob.new(file: file)
blob2.save

# blob1 and blob2 reference the same record
blob1.id == blob2.id  # => true
```

### Attachments

Attachments link blobs to your records:

```ruby
# Create attachment explicitly
attachment = LaserBlob::Attachment.create(
  record: user,
  blob: blob,
  filename: "avatar.jpg",
  type: "avatar"
)

# Access attachment properties
attachment.filename      # => "avatar.jpg"
attachment.content_type  # => "image/jpeg"
attachment.size          # => 102400
attachment.url           # Delegates to blob.url
```

### Nested Attributes

You can use nested attributes with attachments:

```ruby
class Post < ApplicationRecord
  has_many_blobs :images
  accepts_nested_attributes_for :images
end

# In your controller
post.update(
  images_attributes: [
    { blob_id: blob.id, filename: "image1.jpg" },
    { blob_id: blob2.id, filename: "image2.jpg" }
  ]
)
```

## Architecture

### Models

- **LaserBlob::Blob**: Base model for all blobs
  - `LaserBlob::Blob::Image`: Image blobs with metadata extraction
  - `LaserBlob::Blob::Video`: Video blobs with metadata extraction
  - `LaserBlob::Blob::PDF`: PDF blobs with metadata extraction

- **LaserBlob::Attachment**: Polymorphic join model linking blobs to records

### Storage Backends

- **LaserBlob::Storage::Filesystem**: Store blobs on local filesystem
- **LaserBlob::Storage::S3**: Store blobs on S3 or S3-compatible services

### Database Schema

#### Blobs Table

```ruby
create_table :blobs, id: :uuid do |t|
  t.string :type                           # STI type
  t.bigint :size, null: false              # File size in bytes
  t.string :content_type, null: false      # MIME type
  t.jsonb :metadata, default: {}           # Type-specific metadata
  t.binary :sha1, limit: 20, null: false   # SHA1 hash for deduplication
  t.timestamps
end

add_index :blobs, :sha1
add_index :blobs, [:type, :sha1]
```

#### Attachments Table

```ruby
create_table :attachments, id: :uuid do |t|
  t.string :type                    # Attachment type (e.g., "avatar", "photo")
  t.integer :order, default: 0      # Order for has_many_blobs
  t.string :filename                # Original filename
  t.string :record_type, null: false  # Polymorphic record type
  t.uuid :record_id, null: false      # Polymorphic record ID
  t.uuid :blob_id, null: false      # Reference to blob
  t.timestamps
end

add_index :attachments, [:record_type, :record_id]
add_index :attachments, :blob_id
add_index :attachments, [:blob_id, :record_id, :record_type, :type, :filename],
          unique: true
```

## Advanced Usage

### Custom Blob Types

Create custom blob types by subclassing `LaserBlob::Blob`:

```ruby
class LaserBlob::Blob::Audio < LaserBlob::Blob
  validates :content_type, format: /\Aaudio\/.*\Z/

  def duration
    metadata['duration']
  end

  def self.process(record, path)
    # Extract audio metadata
    # record.metadata = { 'duration' => ..., 'bitrate' => ... }
  end
end
```

### Storage Adapter Interface

Create custom storage adapters by implementing:

```ruby
class MyStorage
  def local?
    # Return true if storage is local, false otherwise
  end

  def write(id, file, options = {})
    # Write file to storage
  end

  def read(id)
    # Read file from storage
  end

  def delete(id)
    # Delete file from storage
  end

  def exists?(id)
    # Check if file exists
  end

  def url(id, **options)
    # Generate URL for file
  end

  def copy_to_tempfile(id, basename: nil, &block)
    # Copy file to temporary location and yield to block
  end
end
```

## Development

After checking out the repo, run:

```bash
bundle install
```

To run tests:

```bash
rails test
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/laserkats/laserblob.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
