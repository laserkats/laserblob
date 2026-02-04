ENV["RAILS_ENV"] = "test"

# Configure database before loading Rails
ENV["DATABASE_URL"] = "sqlite3:#{File.expand_path("dummy/db/test.sqlite3", __dir__)}"

require_relative "dummy/config/environment"
require "rails/test_help"
require "minitest/autorun"
require "factory_bot"
require "webmock/minitest"

# Load factories
FactoryBot.definition_file_paths = [File.expand_path("factories", __dir__)]
FactoryBot.find_definitions

# Load schema
ActiveRecord::Schema.verbose = false
load File.expand_path("dummy/db/schema.rb", __dir__)

# Configure models for testing with string IDs
[LaserBlob::Blob, LaserBlob::Attachment, Document].each do |klass|
  klass.class_eval do
    before_create { self.id ||= SecureRandom.uuid }
  end
end

LaserBlob::Blob.class_eval do
  serialize :metadata, coder: JSON
end

# Configure storage for tests
LaserBlob.storage_config = {
  storage: 'filesystem',
  path: Rails.root.join('tmp', 'storage', 'blobs')
}

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  # Clean up storage after each test
  teardown do
    FileUtils.rm_rf(Rails.root.join('tmp', 'storage'))
  end
end

FIXTURES = Pathname.new(File.expand_path("fixtures/files", __dir__))
