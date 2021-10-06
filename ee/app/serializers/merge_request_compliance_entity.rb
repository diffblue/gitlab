# frozen_string_literal: true

class MergeRequestComplianceEntity < Grape::Entity
  include MergeRequestMetricsHelper
  include RequestAwareEntity

  SUCCESS_APPROVAL_STATUS = :success
  WARNING_APPROVAL_STATUS = :warning
  FAILED_APPROVAL_STATUS = :failed

  expose :id
  expose :title
  expose :merged_at
  expose :milestone

  expose :path do |merge_request|
    merge_request_path(merge_request)
  end

  expose :issuable_reference do |merge_request|
    merge_request.to_reference(merge_request.project.group)
  end

  expose :reference do |merge_request|
    merge_request.to_reference
  end

  expose :project do |merge_request|
    {
      avatar_url: merge_request.project.avatar_url,
      name: merge_request.project.name,
      web_url: merge_request.project.web_url
    }
  end

  expose :author, using: API::Entities::UserBasic
  expose :approved_by_users, using: API::Entities::UserBasic
  expose :committers, using: API::Entities::UserBasic
  expose :participants, using: API::Entities::UserBasic
  expose :merged_by, using: API::Entities::UserBasic

  expose :pipeline_status, if: -> (*) { can_read_pipeline? }, with: DetailedStatusEntity
  expose :approval_status

  expose :target_branch
  expose :target_branch_uri, if: -> (merge_request) { merge_request.target_branch_exists? }
  expose :source_branch
  expose :source_branch_uri, if: -> (merge_request) { merge_request.source_branch_exists? }
  expose :compliance_management_framework

  private

  alias_method :merge_request, :object

  def can_read_pipeline?
    can?(request.current_user, :read_pipeline, merge_request.head_pipeline)
  end

  def pipeline_status
    merge_request.head_pipeline.detailed_status(request.current_user)
  end

  def approval_status
    # All these checks should be false for this to pass as a success
    # If any are true then there is a violation of the separation of duties
    checks = [
        merge_request.authors_can_approve?,
        merge_request.committers_can_approve?,
        merge_request.approvals_required < 2
    ]

    return FAILED_APPROVAL_STATUS if checks.all?
    return WARNING_APPROVAL_STATUS if checks.any?

    SUCCESS_APPROVAL_STATUS
  end

  def merged_by
    build_metrics(merge_request).merged_by
  end

  def target_branch_uri
    project_ref_path(merge_request.project, merge_request.target_branch)
  end

  def source_branch_uri
    project_ref_path(merge_request.project, merge_request.source_branch)
  end

  def compliance_management_framework
    merge_request.project&.compliance_management_framework
  end
end
