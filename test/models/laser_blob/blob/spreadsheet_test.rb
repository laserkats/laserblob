require 'test_helper'

class LaserBlob::Blob::SpreadsheetTest < ActiveSupport::TestCase

  test 'spreadsheet type is assigned for spreadsheet content types' do
    LaserBlob::Blob::Spreadsheet::CONTENT_TYPES.each do |content_type|
      blob = LaserBlob::Blob.new(data: 'fake spreadsheet', content_type: content_type)
      assert_equal LaserBlob::Blob::Spreadsheet, blob.class, "Expected Spreadsheet for #{content_type}"
    end
  end

  test 'spreadsheet validates content_type' do
    blob = LaserBlob::Blob::Spreadsheet.new(data: 'test', content_type: 'text/plain')
    blob.size = 4
    blob.sha1 = Digest::SHA1.digest('test')
    assert_not blob.valid?
    assert blob.errors[:content_type].present?
  end

  test 'sheet_count accessor' do
    blob = LaserBlob::Blob::Spreadsheet.new
    blob.metadata = { 'sheets' => [
      { 'name' => 'Sheet1', 'rows' => 10, 'columns' => 5 },
      { 'name' => 'Sheet2', 'rows' => 20, 'columns' => 3 }
    ] }

    assert_equal 2, blob.sheet_count
  end

  test 'row_count accessor sums rows across sheets' do
    blob = LaserBlob::Blob::Spreadsheet.new
    blob.metadata = { 'sheets' => [
      { 'name' => 'Sheet1', 'rows' => 10, 'columns' => 5 },
      { 'name' => 'Sheet2', 'rows' => 20, 'columns' => 3 }
    ] }

    assert_equal 30, blob.row_count
  end

  test 'column_count accessor returns max columns' do
    blob = LaserBlob::Blob::Spreadsheet.new
    blob.metadata = { 'sheets' => [
      { 'name' => 'Sheet1', 'rows' => 10, 'columns' => 5 },
      { 'name' => 'Sheet2', 'rows' => 20, 'columns' => 3 }
    ] }

    assert_equal 5, blob.column_count
  end

  test 'sheets accessor returns sheets array' do
    sheets = [
      { 'name' => 'Sheet1', 'rows' => 10, 'columns' => 5 },
      { 'name' => 'Sheet2', 'rows' => 20, 'columns' => 3 }
    ]
    blob = LaserBlob::Blob::Spreadsheet.new
    blob.metadata = { 'sheets' => sheets }

    assert_equal sheets, blob.sheets
  end

  test 'accessors return defaults when metadata is empty' do
    blob = LaserBlob::Blob::Spreadsheet.new
    blob.metadata = {}

    assert_equal 0, blob.sheet_count
    assert_equal 0, blob.row_count
    assert_equal 0, blob.column_count
    assert_equal [], blob.sheets
  end

  test 'extension_for_content_type returns correct extensions' do
    assert_equal :csv, LaserBlob::Blob::Spreadsheet.extension_for_content_type('text/csv')
    assert_equal :csv, LaserBlob::Blob::Spreadsheet.extension_for_content_type('application/csv')
    assert_equal :xls, LaserBlob::Blob::Spreadsheet.extension_for_content_type('application/vnd.ms-excel')
    assert_equal :xlsx, LaserBlob::Blob::Spreadsheet.extension_for_content_type('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
  end

  test 'processing spreadsheet extracts correct metadata' do
    skip "Requires roo gem" unless defined?(Roo) || (require 'roo' rescue false)

    spreadsheet = LaserBlob::Blob.create!(
      file: Rack::Test::UploadedFile.new(FIXTURES.join('test.csv'), 'text/csv', true)
    )
    spreadsheet.open do |file|
      LaserBlob::Blob::Spreadsheet.process(spreadsheet, file.path)
    end

    assert_equal 1, spreadsheet.sheet_count
    assert_equal 4, spreadsheet.row_count
    assert_equal 3, spreadsheet.column_count
    assert_equal [{ 'name' => 'default', 'rows' => 4, 'columns' => 3 }], spreadsheet.sheets
  end

end
