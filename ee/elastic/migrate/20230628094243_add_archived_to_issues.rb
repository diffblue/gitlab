# frozen_string_literal: true

class AddArchivedToIssues < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  private

  def index_name
    Issue.__elasticsearch__.index_name
  end

  def new_mappings
    {
      archived: {
        type: 'boolean'
      }
    }
  end
end
