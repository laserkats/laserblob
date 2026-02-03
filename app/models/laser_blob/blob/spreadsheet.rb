module LaserBlob
  class Blob::Spreadsheet < Blob
    CONTENT_TYPES = [
      'text/csv',
      'application/csv',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    ].freeze

    validates :content_type, presence: true, inclusion: { in: CONTENT_TYPES }

    def sheet_count
      metadata['sheets']&.size || 0
    end

    def row_count
      metadata['sheets']&.sum { |s| s['rows'] } || 0
    end

    def column_count
      metadata['sheets']&.map { |s| s['columns'] }&.max || 0
    end

    def sheets
      metadata['sheets'] || []
    end

    def self.process(record, path)
      require 'roo' unless defined?(Roo)

      spreadsheet = Roo::Spreadsheet.open(path, extension: extension_for_content_type(record.content_type))

      record.metadata = {
        'sheets' => spreadsheet.sheets.map do |sheet_name|
          spreadsheet.default_sheet = sheet_name
          {
            'name' => sheet_name,
            'rows' => spreadsheet.last_row || 0,
            'columns' => spreadsheet.last_column || 0
          }
        end
      }
    end

    def self.extension_for_content_type(content_type)
      case content_type
      when 'text/csv', 'application/csv'
        :csv
      when 'application/vnd.ms-excel'
        :xls
      when 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        :xlsx
      end
    end
  end
end
