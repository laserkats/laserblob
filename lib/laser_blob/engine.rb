require "rails"

module LaserBlob
  class Engine < ::Rails::Engine
    isolate_namespace LaserBlob

    config.autoload_paths << File.expand_path('../../app/models', __dir__)

    config.generators do |g|
      g.test_framework :test_unit, fixture: false
    end

    initializer "laserblob.active_record", before: :load_config_initializers do
      ActiveSupport.on_load(:active_record) do
        require "laser_blob/model_extensions"
        ActiveRecord::Base.include(LaserBlob::ModelExtensions)
      end
    end

    initializer "laserblob.sqlite_serialization", after: "active_record.initialize_database" do
      if ActiveRecord::Base.connection.adapter_name.downcase.include?('sqlite')
        LaserBlob::Blob.serialize :metadata, coder: JSON
      end
    end

    initializer "laserblob.eager_load_blob_subclasses", after: :load_config_initializers do
      # Eagerly load Blob subclasses so they appear in descendants
      # This is needed for content_type_class to find the right subclass
      Dir[File.expand_path('../../app/models/laser_blob/blob/*.rb', __dir__)].each do |file|
        require file
      end
    end
  end
end
