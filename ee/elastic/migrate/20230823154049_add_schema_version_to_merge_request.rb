# frozen_string_literal: true

class AddSchemaVersionToMergeRequest < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  private

  def index_name
    ::Elastic::Latest::MergeRequestConfig.index_name
  end

  def new_mappings
    {
      schema_version: {
        type: 'integer'
      }
    }
  end
end
