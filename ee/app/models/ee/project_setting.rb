# frozen_string_literal: true

module EE
  module ProjectSetting
    extend ActiveSupport::Concern

    prepended do
      belongs_to :push_rule

      scope :has_vulnerabilities, -> { where('has_vulnerabilities IS TRUE') }
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
