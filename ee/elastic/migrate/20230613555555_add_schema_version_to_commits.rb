# frozen_string_literal: true

class AddSchemaVersionToCommits < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  private

  def index_name
    ::Elastic::Latest::CommitConfig.index_name
  end

  def new_mappings
    {
      schema_version: {
        type: 'integer'
      }
    }
  end
end
