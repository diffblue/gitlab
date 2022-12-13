# frozen_string_literal: true

class AddTraversalIdsToOriginalIndexMapping < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  private

  def index_name
    Repository.__elasticsearch__.index_name
  end

  def new_mappings
    {
      traversal_ids: {
        type: 'keyword'
      }
    }
  end
end
