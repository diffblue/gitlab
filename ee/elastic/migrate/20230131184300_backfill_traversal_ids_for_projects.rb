# frozen_string_literal: true

class BackfillTraversalIdsForProjects < Elastic::Migration
  include Elastic::MigrationBackfillHelper

  batched!
  batch_size 10_000
  throttle_delay 3.minutes

  DOCUMENT_TYPE = Project
  UPDATE_BATCH_SIZE = 500

  private

  def index_name
    DOCUMENT_TYPE.__elasticsearch__.index_name
  end

  def field_name
    :traversal_ids
  end
end
