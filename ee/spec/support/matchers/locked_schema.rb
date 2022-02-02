# frozen_string_literal: true

class SchemaVersion # rubocop:disable Gitlab/NamespacedClass
  def initialize(model)
    @model = model
  end

  def current
    (column_names + index_names).sort
                                .join('-')
                                .then { |s| Digest::SHA256.hexdigest(s) }
  end

  private

  attr_reader :model

  delegate :table_name, :connection, to: :model, private: true

  def column_names
    connection.columns(table_name).map(&:name)
  end

  def index_names
    connection.indexes(table_name).map(&:name)
  end
end

RSpec::Matchers.define :have_locked_schema do |locked_version|
  LOCKED_SCHEMA_ERROR_MESSAGE = <<~TEXT
    Schema of the "%<table_name>s" table has been locked and does not match
    with the current version "%<current_schema_version>s".

    Please see "%<reference>s" for more details.
  TEXT

  chain(:reference) do |value|
    @reference = value
  end

  match do
    @table_name = described_class.table_name
    @current_schema_version = SchemaVersion.new(described_class).current

    @current_schema_version == locked_version
  end

  failure_message do
    format(LOCKED_SCHEMA_ERROR_MESSAGE, table_name: @table_name, current_schema_version: @current_schema_version, reference: @reference)
  end
end
