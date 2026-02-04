require_relative "lib/laser_blob/version"

Gem::Specification.new do |spec|
  spec.name        = "laserblob"
  spec.version     = LaserBlob::VERSION
  spec.authors     = ["Jon Bracy", "Ben Ehmke"]
  spec.email       = ["jonbracy@gmail.com", "ben@ehmke.com"]
  spec.homepage    = "https://github.com/laserkats/laserblob"
  spec.summary     = "Content-addressable blob storage for Rails applications"
  spec.description = "LaserBlob provides a Blob model with SHA1-based deduplication, polymorphic attachments, and support for multiple storage backends (filesystem, S3). Includes automatic metadata extraction for images, videos, PDFs, and spreadsheets."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/laserkats/laserblob"
  spec.metadata["changelog_uri"] = "https://github.com/laserkats/laserblob/blob/master/CHANGELOG.md"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.required_ruby_version = ">= 2.7.0"

  spec.add_dependency "rails", ">= 6.1"
  spec.add_dependency "mini_mime", "~> 1.0"

  # Optional dependencies for blob type processing
  spec.add_development_dependency "ruby-vips"
  spec.add_development_dependency "streamio-ffmpeg"
  spec.add_development_dependency "pdf-reader"
  spec.add_development_dependency "roo"
  
  # Optional dependencies for testing
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'factory_bot_rails'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'rack-test'
end
