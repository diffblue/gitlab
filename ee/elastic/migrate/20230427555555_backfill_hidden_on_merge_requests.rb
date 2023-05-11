# frozen_string_literal: true

class BackfillHiddenOnMergeRequests < Elastic::Migration
  include Elastic::MigrationBackfillHelper

  batched!
  batch_size 9_000
  throttle_delay 1.minute

  DOCUMENT_TYPE = MergeRequest
  UPDATE_BATCH_SIZE = 100

  private

  def index_name
    DOCUMENT_TYPE.__elasticsearch__.index_name
  end

  def field_name
    :hidden
  end
end
