# frozen_string_literal: true

class AddHiddenToMergeRequests < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  private

  def index_name
    MergeRequest.__elasticsearch__.index_name
  end

  def new_mappings
    {
      hidden: {
        type: 'boolean'
      }
    }
  end
end
