# frozen_string_literal: true

class ApprovalMergeRequestRule < ApplicationRecord
  include Gitlab::Utils::StrongMemoize
  include ApprovalRuleLike
  include UsageStatistics

  scope :not_matching_pattern, -> (pattern) { code_owner.where.not(name: pattern) }
  scope :matching_pattern, -> (pattern) { code_owner.where(name: pattern) }

  scope :from_project_rule, -> (project_rule) do
    joins(:approval_merge_request_rule_source)
      .where(
        approval_merge_request_rule_sources: { approval_project_rule_id: project_rule.id }
      )
  end
  scope :for_unmerged_merge_requests, -> (merge_requests = nil) do
    query = joins(:merge_request).where.not(merge_requests: { state_id: MergeRequest.available_states[:merged] })

    if merge_requests
      query.where(merge_request_id: merge_requests)
    else
      query
    end
  end
  scope :code_owner_approval_optional, -> { code_owner.where(approvals_required: 0) }
  scope :code_owner_approval_required, -> { code_owner.where('approvals_required > 0') }
  scope :with_added_approval_rules, -> { left_outer_joins(:approval_merge_request_rule_source).where(approval_merge_request_rule_sources: { approval_merge_request_rule_id: nil }) }

  validates :name, uniqueness: { scope: [:merge_request_id, :rule_type, :section] }, unless: :scan_finding?
  validates :name, uniqueness: { scope: [:merge_request_id, :rule_type, :section, :security_orchestration_policy_configuration_id, :orchestration_policy_idx] }, if: :scan_finding?
  validates :rule_type, uniqueness: { scope: :merge_request_id, message: proc { _('any-approver for the merge request already exists') } }, if: :any_approver?

  belongs_to :merge_request, inverse_of: :approval_rules

  # approved_approvers is only populated after MR is merged
  has_and_belongs_to_many :approved_approvers, class_name: 'User', join_table: :approval_merge_request_rules_approved_approvers
  has_one :approval_merge_request_rule_source
  has_one :approval_project_rule, through: :approval_merge_request_rule_source
  has_one :approval_project_rule_project, through: :approval_project_rule, source: :project
  alias_method :source_rule, :approval_project_rule

  before_update :compare_with_project_rule

  validate :validate_approval_project_rule

  enum rule_type: {
    regular: 1,
    code_owner: 2,
    report_approver: 3,
    any_approver: 4
  }

  alias_method :regular, :regular?
  alias_method :code_owner, :code_owner?

  scope :license_compliance, -> { report_approver.license_scanning }
  scope :coverage, -> { report_approver.code_coverage }
  scope :with_head_pipeline, -> { includes(merge_request: [:head_pipeline]) }
  scope :open_merge_requests, -> { merge(MergeRequest.opened) }
  scope :for_checks_that_can_be_refreshed, -> { license_compliance.open_merge_requests.with_head_pipeline }
  scope :with_projects_that_can_override_rules, -> do
    joins(:approval_project_rule_project)
      .where(projects: { disable_overriding_approvers_per_merge_request: [false, nil] })
  end
  scope :modified_from_project_rule, -> { with_projects_that_can_override_rules.where(modified_from_project_rule: true) }

  def self.find_or_create_code_owner_rule(merge_request, entry)
    merge_request.approval_rules.code_owner.where(name: entry.pattern).where(section: entry.section).first_or_create do |rule|
      rule.rule_type = :code_owner
      rule.approvals_required = entry.approvals_required
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def audit_add(_model)
    # no-op
    # only audit on project rule
  end

  def audit_remove(_model)
    # no-op
    # only audit on project rule
  end

  def project
    merge_request.target_project
  end

  def approval_project_rule_id=(approval_project_rule_id)
    self.approval_merge_request_rule_source ||= build_approval_merge_request_rule_source
    self.approval_merge_request_rule_source.approval_project_rule_id = approval_project_rule_id
  end

  # Users who are eligible to approve, including specified group members.
  # Excludes the author if 'self-approval' isn't explicitly
  # enabled on project settings.
  # @return [Array<User>]
  def approvers
    strong_memoize(:approvers) do
      scope_or_array = super

      next scope_or_array unless merge_request.author
      next scope_or_array if project.merge_requests_author_approval?

      if scope_or_array.respond_to?(:where)
        scope_or_array.where.not(id: merge_request.author)
      else
        scope_or_array - [merge_request.author]
      end
    end
  end

  def sync_approved_approvers
    # Before being merged, approved_approvers are dynamically calculated in
    #   ApprovalWrappedRule instead of being persisted.
    #
    return unless merge_request.merged?

    approvers = ApprovalWrappedRule.wrap(merge_request, self).approved_approvers

    self.approved_approver_ids = approvers.map(&:id)
  end

  def self.remove_required_approved(approval_rules)
    where(id: approval_rules).update_all(approvals_required: 0)
  end

  def vulnerability_states_for_branch
    return self.vulnerability_states if merge_request.target_default_branch?

    vulnerability_states.include?(NEWLY_DETECTED) ? [NEWLY_DETECTED] : []
  end

  private

  def compare_with_project_rule
    self.modified_from_project_rule = overridden? ? true : false
  end

  def validate_approval_project_rule
    return if approval_project_rule.blank?
    return if merge_request.project == approval_project_rule.project

    errors.add(:approval_project_rule, 'must be for the same project')
  end
end
