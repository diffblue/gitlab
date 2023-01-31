# frozen_string_literal: true

class AddSchemaVersionToMainIndexMapping < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  private

  def index_name
    Project.__elasticsearch__.index_name
  end

  def new_mappings
    {
      schema_version: {
        type: 'short'
      }
    }
  end
end
