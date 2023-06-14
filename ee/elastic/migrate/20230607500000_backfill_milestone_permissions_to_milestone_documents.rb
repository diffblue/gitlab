# frozen_string_literal: true

class BackfillMilestonePermissionsToMilestoneDocuments < Elastic::Migration
  include Elastic::MigrationBackfillHelper

  batched!
  batch_size 9_000
  throttle_delay 1.minute

  DOCUMENT_TYPE = Milestone

  private

  def index_name
    DOCUMENT_TYPE.__elasticsearch__.index_name
  end

  def field_names
    %w[merge_requests_access_level issues_access_level visibility_level]
  end
end
