# frozen_string_literal: true

class AddSchemaVersionToNote < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  private

  def index_name
    ::Elastic::Latest::NoteConfig.index_name
  end

  def new_mappings
    {
      schema_version: {
        type: 'integer'
      }
    }
  end
end
