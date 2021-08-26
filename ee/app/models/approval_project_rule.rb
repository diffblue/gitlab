# frozen_string_literal: true

class ApprovalProjectRule < ApplicationRecord
  include ApprovalRuleLike
  include Auditable

  UNSUPPORTED_SCANNER = 'cluster_image_scanning'
  SUPPORTED_SCANNERS = (::Ci::JobArtifact::SECURITY_REPORT_FILE_TYPES - [UNSUPPORTED_SCANNER]).freeze
  DEFAULT_SEVERITIES = %w[unknown high critical].freeze

  belongs_to :project
  has_and_belongs_to_many :protected_branches
  has_many :approval_merge_request_rule_sources
  has_many :approval_merge_request_rules, through: :approval_merge_request_rule_sources

  enum rule_type: {
    regular: 0,
    code_owner: 1, # currently unused
    report_approver: 2,
    any_approver: 3
  }

  alias_method :code_owner, :code_owner?
  validate :validate_default_license_report_name, on: :update, if: :report_approver?

  validates :name, uniqueness: { scope: [:project_id, :rule_type] }
  validates :rule_type, uniqueness: { scope: :project_id, message: proc { _('any-approver for the project already exists') } }, if: :any_approver?

  validates :scanners, if: :scanners_changed?, inclusion: { in: SUPPORTED_SCANNERS }
  default_value_for :scanners, allows_nil: false, value: SUPPORTED_SCANNERS

  validates :vulnerabilities_allowed, numericality: { only_integer: true }
  default_value_for :vulnerabilities_allowed, allows_nil: false, value: 0

  validates :severity_levels, inclusion: { in: ::Enums::Vulnerability.severity_levels.keys }
  default_value_for :severity_levels, allows_nil: false, value: DEFAULT_SEVERITIES

  def applies_to_branch?(branch)
    return true if protected_branches.empty?

    protected_branches.matching(branch).any?
  end

  def source_rule
    nil
  end

  def section
    nil
  end

  def apply_report_approver_rules_to(merge_request)
    report_type = report_type_for(self)
    rule = merge_request
      .approval_rules
      .report_approver
      .find_or_initialize_by(report_type: report_type)
    rule.update!(attributes_to_apply_for(report_type))
    rule
  end

  def audit_add(model)
    push_audit_event("Added #{model.class.name} #{model.name} to approval group on #{self.name} rule")
  end

  def audit_remove(model)
    push_audit_event("Removed #{model.class.name} #{model.name} from approval group on #{self.name} rule")
  end

  private

  def report_type_for(rule)
    ApprovalProjectRule::REPORT_TYPES_BY_DEFAULT_NAME[rule.name]
  end

  def attributes_to_apply_for(report_type)
    attributes
      .slice('approvals_required', 'name')
      .merge(
        users: users,
        groups: groups,
        approval_project_rule: self,
        rule_type: :report_approver,
        report_type: report_type
      )
  end

  def validate_default_license_report_name
    return unless name_changed?
    return unless name_was == ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT

    errors.add(:name, _("cannot be modified"))
  end
end
