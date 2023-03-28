# frozen_string_literal: true

# This entity represents a merge request that blocks another MR from being
# merged.
#
# Don't use MergeRequestWidgetEntity - it's far too easy to create a loop
class BlockingMergeRequestEntity < Grape::Entity
  include ::RequestAwareEntity

  expose :id
  expose :iid
  expose :title
  expose :state

  expose :reference do |blocking_mr, options|
    blocking_mr.to_reference(options[:from_project])
  end

  expose :web_url do |blocking_mr|
    merge_request_path(blocking_mr)
  end

  expose :head_pipeline,
    if: -> (_, _) { can_read_head_pipeline? },
    using: ::API::Entities::Ci::Pipeline

  expose :assignees, using: ::API::Entities::UserBasic
  expose :milestone, using: ::API::Entities::Milestone
  expose :created_at
  expose :merged_at
  expose :closed_at do |blocking_mr|
    blocking_mr.metrics&.latest_closed_at
  end

  private

  def can_read_head_pipeline?
    can?(request.current_user, :read_pipeline, object.head_pipeline)
  end
end
