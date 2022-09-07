# frozen_string_literal: true

class AddLabelIdsAndSchemaVersionToIssuesMapping < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  private

  def index_name
    Issue.__elasticsearch__.index_name
  end

  def new_mappings
    {
      label_ids: {
        type: 'keyword'
      },
      schema_version: {
        type: 'short'
      }
    }
  end
end
