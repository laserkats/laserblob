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
  end
end
