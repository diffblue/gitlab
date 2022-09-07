# frozen_string_literal: true

class BackfillLabelIdsForIssues < Elastic::Migration
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
    # We use schema_version here because it doesn't exist for documents without label_ids
    # We can't use label_ids because Elasticsearch treats [] as a non-existent value
    :schema_version
  end
end
