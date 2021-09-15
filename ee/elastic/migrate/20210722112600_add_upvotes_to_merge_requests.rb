# frozen_string_literal: true

class AddUpvotesToMergeRequests < Elastic::Migration
  include Elastic::MigrationBackfillHelper

  batched!
  batch_size 5000
  throttle_delay 3.minutes

  DOCUMENT_TYPE = MergeRequest

  def new_mappings
    { upvotes: { type: 'integer' } }
  end

  private

  def index_name
    DOCUMENT_TYPE.__elasticsearch__.index_name
  end

  def field_name
    :upvotes
  end
end
