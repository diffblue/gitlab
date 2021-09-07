# frozen_string_literal: true

class BackfillNamespaceAncestryForIssues < Elastic::Migration
  include Elastic::MigrationBackfillHelper

  batched!
  throttle_delay 3.minutes

  DOCUMENT_TYPE = Issue
  QUERY_BATCH_SIZE = 5000
  UPDATE_BATCH_SIZE = 100

  private

  def index_name
    DOCUMENT_TYPE.__elasticsearch__.index_name
  end

  def field_name
    :namespace_ancestry
  end
end
