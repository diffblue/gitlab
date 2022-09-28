# frozen_string_literal: true

module Security
  module ScanResultPolicy
    extend ActiveSupport::Concern

    # Used for both policies and rules
    LIMIT = 5

    APPROVERS_LIMIT = 300

    SCAN_FINDING = 'scan_finding'

    REQUIRE_APPROVAL = 'require_approval'

    included do
      has_many :approval_merge_request_rules,
        foreign_key: 'security_orchestration_policy_configuration_id',
        inverse_of: :security_orchestration_policy_configuration
      has_many :approval_project_rules,
        foreign_key: 'security_orchestration_policy_configuration_id',
        inverse_of: :security_orchestration_policy_configuration

      def delete_scan_finding_rules
        if project? # To be removed in https://gitlab.com/gitlab-org/gitlab/-/issues/369473#feature-update
          project.approval_rules.scan_finding.delete_all
          project.approval_merge_request_rules.scan_finding.delete_all
        else
          approval_merge_request_rules.delete_all
          approval_project_rules.delete_all
        end
      end

      def active_scan_result_policies
        return [] if project.blank?

        scan_result_policies&.select { |config| config[:enabled] }&.first(LIMIT)
      end

      def scan_result_policies
        policy_by_type(:scan_result_policy)
      end
    end
  end
end
