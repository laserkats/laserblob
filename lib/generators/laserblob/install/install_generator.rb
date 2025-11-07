require 'rails/generators'
require 'rails/generators/migration'

module Laserblob
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      def self.next_migration_number(path)
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end

      def copy_migrations
        migration_template "create_blobs.rb", "db/migrate/create_blobs.rb"
        sleep 1 # Ensure unique timestamp
        migration_template "create_attachments.rb", "db/migrate/create_attachments.rb"
      end

      def create_initializer
        template "initializer.rb", "config/initializers/laser_blob.rb"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
