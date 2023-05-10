# frozen_string_literal: true

module ApprovalRuleLike
  extend ActiveSupport::Concern
  include EachBatch

  DEFAULT_NAME = 'Default'
  DEFAULT_NAME_FOR_LICENSE_REPORT = 'License-Check'
  DEFAULT_NAME_FOR_COVERAGE = 'Coverage-Check'
  APPROVALS_REQUIRED_MAX = 100
  ALL_MEMBERS = 'All Members'
  NEWLY_DETECTED = 'newly_detected'
  NEW_NEEDS_TRIAGE = 'new_needs_triage'
  NEW_DISMISSED = 'new_dismissed'

  NEWLY_DETECTED_STATUSES = [NEWLY_DETECTED, NEW_NEEDS_TRIAGE, NEW_DISMISSED].freeze

  included do
    has_and_belongs_to_many :users,
      after_add: :audit_add, after_remove: :audit_remove
    has_and_belongs_to_many :groups,
      class_name: 'Group', join_table: "#{self.table_name}_groups",
      after_add: :audit_add, after_remove: :audit_remove
    has_many :group_users, -> { distinct }, through: :groups, source: :users

    belongs_to :security_orchestration_policy_configuration, class_name: 'Security::OrchestrationPolicyConfiguration', optional: true
    belongs_to :scan_result_policy_read,
      class_name: 'Security::ScanResultPolicyRead',
      foreign_key: 'scan_result_policy_id',
      inverse_of: :security_orchestration_policy_configuration,
      optional: true

    enum report_type: {
      vulnerability: 1, # To be removed after all MRs (related to https://gitlab.com/gitlab-org/gitlab/-/issues/356996) get merged
      license_scanning: 2,
      code_coverage: 3,
      scan_finding: 4
    }

    validates :name, presence: true
    validates :approvals_required, numericality: { less_than_or_equal_to: APPROVALS_REQUIRED_MAX, greater_than_or_equal_to: 0 }
    validates :report_type, presence: true, if: :report_approver?

    scope :with_users, -> { preload(:users, :group_users) }
    scope :regular_or_any_approver, -> { where(rule_type: [:regular, :any_approver]) }
    scope :for_groups, -> (groups) { joins(:groups).where(approval_project_rules_groups: { group_id: groups }) }
    scope :including_scan_result_policy_read, -> { includes(:scan_result_policy_read) }
    scope :with_scan_result_policy_read, -> { where.not(scan_result_policy_id: nil) }
    scope :for_policy_configuration, -> (configuration_id) do
      where(security_orchestration_policy_configuration_id: configuration_id)
    end
  end

  def audit_add
    raise NotImplementedError
  end

  def audit_remove
    raise NotImplementedError
  end

  # Users who are eligible to approve, including specified group members.
  # @return [Array<User>]
  def approvers
    @approvers ||= if Feature.enabled?(:scan_result_role_action, project)
                     filter_inactive_approvers(with_role_approvers)
                   else
                     filter_inactive_approvers(direct_approvers)
                   end
  end

  def code_owner?
    raise NotImplementedError
  end

  def regular?
    raise NotImplementedError
  end

  def report_approver?
    raise NotImplementedError
  end

  def any_approver?
    raise NotImplementedError
  end

  def user_defined?
    regular? || any_approver?
  end

  def overridden?
    return false unless source_rule.present?

    source_rule.name != name ||
      source_rule.approvals_required != approvals_required ||
      source_rule.user_ids.to_set != user_ids.to_set ||
      source_rule.group_ids.to_set != group_ids.to_set
  end

  def from_scan_result_policy?
    scan_finding? || (license_scanning? && scan_result_policy_id.present?)
  end

  private

  def direct_approvers
    if users.loaded? && group_users.loaded?
      users | group_users
    else
      User.from_union([users, group_users])
    end
  end

  def with_role_approvers
    if users.loaded? && group_users.loaded?
      users | group_users | role_approvers
    else
      User.from_union([users, group_users, role_approvers])
    end
  end

  def role_approvers
    return User.none unless scan_result_policy_read

    project.team.members_with_access_levels(scan_result_policy_read.role_approvers)
  end

  def filter_inactive_approvers(approvers)
    if approvers.respond_to?(:with_state)
      approvers.with_state(:active)
    else
      approvers.select(&:active?)
    end
  end
end
