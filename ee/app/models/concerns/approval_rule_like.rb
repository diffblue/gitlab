# frozen_string_literal: true

module ApprovalRuleLike
  extend ActiveSupport::Concern

  DEFAULT_NAME = 'Default'
  DEFAULT_NAME_FOR_LICENSE_REPORT = 'License-Check'
  DEFAULT_NAME_FOR_VULNERABILITY_REPORT = 'Vulnerability-Check'
  DEFAULT_NAME_FOR_COVERAGE = 'Coverage-Check'
  REPORT_TYPES_BY_DEFAULT_NAME = {
    DEFAULT_NAME_FOR_LICENSE_REPORT => :license_scanning,
    DEFAULT_NAME_FOR_VULNERABILITY_REPORT => :vulnerability,
    DEFAULT_NAME_FOR_COVERAGE => :code_coverage
  }.freeze
  APPROVALS_REQUIRED_MAX = 100
  ALL_MEMBERS = 'All Members'

  included do
    has_and_belongs_to_many :users,
      after_add: :audit_add, after_remove: :audit_remove
    has_and_belongs_to_many :groups,
      class_name: 'Group', join_table: "#{self.table_name}_groups",
      after_add: :audit_add, after_remove: :audit_remove
    has_many :group_users, -> { distinct }, through: :groups, source: :users

    validates :name, presence: true
    validates :approvals_required, numericality: { less_than_or_equal_to: APPROVALS_REQUIRED_MAX, greater_than_or_equal_to: 0 }

    scope :with_users, -> { preload(:users, :group_users) }
    scope :regular_or_any_approver, -> { where(rule_type: [:regular, :any_approver]) }
    scope :for_groups, -> (groups) { joins(:groups).where(approval_project_rules_groups: { group_id: groups }) }
    scope :vulnerability_reports, -> { where(rule_type: :report_approver, name: ApprovalRuleLike::DEFAULT_NAME_FOR_VULNERABILITY_REPORT) }
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
    @approvers ||= if users.loaded? && group_users.loaded?
                     users | group_users
                   else
                     User.from_union([users, group_users])
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
end
