# frozen_string_literal: true

module EE
  module ProjectSetting
    extend ActiveSupport::Concern

    prepended do
      belongs_to :push_rule

      scope :has_vulnerabilities, -> { where('has_vulnerabilities IS TRUE') }

      validates :mirror_branch_regex, absence: true, if: -> { project&.only_mirror_protected_branches? }
      validates :mirror_branch_regex, untrusted_regexp: true, length: { maximum: 255 }
      validates :product_analytics_instrumentation_key, length: { maximum: 255 }, allow_blank: true
    end

    def selective_code_owner_removals
      project.licensed_feature_available?(:merge_request_approvers) &&
        ComplianceManagement::MergeRequestApprovalSettings::Resolver
        .new(project.group, project: project)
        .selective_code_owner_removals
        .value
    end
  end
end
