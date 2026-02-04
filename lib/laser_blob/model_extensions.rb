module LaserBlob
  module ModelExtensions
    extend ActiveSupport::Concern

    class_methods do
      def has_one_blob(name, only: nil, dependent: :destroy)
        has_one :"#{name}", -> { where(type: name) }, class_name: "::LaserBlob::Attachment", as: :record, inverse_of: :record, dependent: dependent

        if only
          allowed_blob_types = only.map do |type|
            if type.is_a?(Class)
              type
            else
              "LaserBlob::Blob::#{type.to_s.classify}".constantize
            end
          end

          define_method(:"validate_#{name}_blob_type") do
            attachment = send(name)
            return unless attachment&.blob
            unless allowed_blob_types.any? { |type| attachment.blob.is_a?(type) }
              allowed_names = allowed_blob_types.map { |t| t.name.demodulize.downcase }
              errors.add(name, "has invalid blob type '#{attachment.blob.class.name.demodulize.downcase}'. Allowed types: #{allowed_names.join(', ')}")
            end
          end
          validate :"validate_#{name}_blob_type"
        end

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{name}_attributes=(attrs)
            attachment = if self.#{name} && self.#{name}.id == (attrs[:id] || attrs['id'])
              self.#{name}
            end

            if attachment
              attachment.order = 0
              attachment.filename = (attrs[:filename] || attrs['filename']) if (attrs[:filename] || attrs['filename'])
              attachment.blob_id = (attrs[:blob_id] || attrs['blob_id']) if (attrs[:blob_id] || attrs['blob_id'])
            else
              attachment = LaserBlob::Attachment.new({
                order: 0,
                filename: (attrs[:filename] || attrs['filename']),
                blob_id: (attrs[:blob_id] || attrs['blob_id']),
                type: '#{name}'
              })
            end

            self.#{name} = attachment
          end

          def #{name}=(file)
            if file && !file.is_a?(LaserBlob::Attachment)
              file = LaserBlob::Attachment.new({
                blob: file,
                filename: LaserBlob::BlobHelpers.filename_from_file(file),
                type: '#{name}'
              })
            elsif file
              file.type = '#{name}'
            end
            association(:#{name}).writer(file)
          end
        RUBY
      end

      def has_many_blobs(name, only: nil, **options)
        options[:dependent] ||= :destroy
        options = {
          dependent: :destroy,
          autosave: true,
          inverse_of: :record,
          as: :record,
          class_name: '::LaserBlob::Attachment'
        }.merge(options)
        singular = name.to_s.singularize
        has_many :"#{name}", -> { where(type: singular).order(order: :asc) }, **options

        if only
          allowed_blob_types = only.map do |type|
            if type.is_a?(Class)
              type
            else
              "LaserBlob::Blob::#{type.to_s.classify}".constantize
            end
          end

          define_method(:"validate_#{name}_blob_types") do
            send(name).each do |attachment|
              next unless attachment.blob
              unless allowed_blob_types.any? { |type| attachment.blob.is_a?(type) }
                allowed_names = allowed_blob_types.map { |t| t.name.demodulize.downcase }
                errors.add(name, "contains invalid blob type '#{attachment.blob.class.name.demodulize.downcase}'. Allowed types: #{allowed_names.join(', ')}")
              end
            end
          end
          validate :"validate_#{name}_blob_types"
        end

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{name}_attributes=(attributes)
            if !attributes.is_a?(Array)
              raise ArgumentError, "Array expected for attributes `#{name}`, got \#{attributes.class.name} (\#{attributes.inspect})"
            end

            attachments = attributes.map.with_index do |attrs, i|
              attachment = self.#{name}.find { |a| a.id == (attrs[:id] || attrs['id']) }

              if attachment
                attachment.order = i
                attachment.filename = (attrs[:filename] || attrs['filename']) if (attrs[:filename] || attrs['filename'])
                attachment.blob_id = (attrs[:blob_id] || attrs['blob_id']) if (attrs[:blob_id] || attrs['blob_id'])
                attachment
              else
                LaserBlob::Attachment.new({
                  order: i,
                  filename: (attrs[:filename] || attrs['filename']),
                  blob_id: (attrs[:blob_id] || attrs['blob_id']),
                  type: '#{singular}'
                })
              end
            end

            self.#{name} = attachments
          end

          def #{name}=(files)
            files = files.map.with_index do |file, i|
              if file.is_a?(LaserBlob::Attachment)
                file.type = '#{singular}'
                file.order = i
                file
              elsif file.is_a?(LaserBlob::Blob)
                LaserBlob::Attachment.new({
                  order: i,
                  type: '#{singular}',
                  blob: file,
                  filename: LaserBlob::BlobHelpers.filename_from_file(file)
                })
              else
                LaserBlob::Attachment.new({
                  order: i,
                  type: '#{singular}',
                  blob: LaserBlob::Blob.new(file: file),
                  filename: LaserBlob::BlobHelpers.filename_from_file(file)
                })
              end
            end

            association(:#{name}).writer(files)
          end
        RUBY
      end
    end
  end
end
