# frozen_string_literal: true

class RedoBackfillNamespaceAncestryIdsForIssues < Elastic::Migration
  include Elastic::MigrationBackfillHelper

  batched!
  batch_size 5000
  throttle_delay 3.minutes

  DOCUMENT_TYPE = Issue
  UPDATE_BATCH_SIZE = 100

  private

  def index_name
    DOCUMENT_TYPE.__elasticsearch__.index_name
  end

  def field_name
    :namespace_ancestry_ids
  end
end
