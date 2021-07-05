# frozen_string_literal: true

class RefreshLicenseComplianceChecksWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :license_compliance
  weight 2

  def perform(project_id)
    project = Project.find(project_id)
    project_approval_rule = project
      .approval_rules
      .report_approver
      .find_by_name!(ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT)

    approval_rules = project.approval_merge_request_rules.for_checks_that_can_be_refreshed
    approval_rules.find_each do |approval_rule|
      approval_rule.refresh_required_approvals!(project_approval_rule)
    end
    # If the project or project approval rule is deleted
    # before this job runs, then it is possible that
    # the project and project approval rule record
    # will not be found.
  rescue ActiveRecord::RecordNotFound => error
    logger.error(error.message)
  end
end
