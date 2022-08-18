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
      delegate :approval_rules, to: :project, allow_nil: true

      def delete_scan_finding_rules
        return unless project?

        project.approval_rules.scan_finding.delete_all
        project.approval_merge_request_rules.scan_finding.delete_all
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
