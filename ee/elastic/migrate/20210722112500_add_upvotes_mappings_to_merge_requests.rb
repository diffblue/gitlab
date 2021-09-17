# frozen_string_literal: true

class AddUpvotesMappingsToMergeRequests < Elastic::Migration
  include Elastic::MigrationUpdateMappingsHelper

  DOCUMENT_TYPE = MergeRequest

  private

  def index_name
    DOCUMENT_TYPE.__elasticsearch__.index_name
  end

  def new_mappings
    { upvotes: { type: 'integer' } }
  end
end
