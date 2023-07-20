# frozen_string_literal: true

class AddArchivedToMergeRequests < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  private

  def index_name
    MergeRequest.__elasticsearch__.index_name
  end

  def new_mappings
    {
      archived: {
        type: 'boolean'
      }
    }
  end
end
