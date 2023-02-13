# frozen_string_literal: true

module Security
  module ScanResultPolicy
    extend ActiveSupport::Concern

    # Used for both policies and rules
    LIMIT = 5

    APPROVERS_LIMIT = 300

    SCAN_FINDING = 'scan_finding'
    LICENSE_FINDING = 'license_finding'

    REQUIRE_APPROVAL = 'require_approval'

    included do
      has_many :scan_result_policy_reads,
        class_name: 'Security::ScanResultPolicyRead',
        foreign_key: 'security_orchestration_policy_configuration_id',
        inverse_of: :security_orchestration_policy_configuration
      has_many :approval_merge_request_rules,
        foreign_key: 'security_orchestration_policy_configuration_id',
        inverse_of: :security_orchestration_policy_configuration
      has_many :approval_project_rules,
        foreign_key: 'security_orchestration_policy_configuration_id',
        inverse_of: :security_orchestration_policy_configuration

      def delete_scan_finding_rules
        approval_merge_request_rules.each_batch { |batch| delete_batch(batch) }
        approval_project_rules.each_batch { |batch| delete_batch(batch) }
      end

      def delete_scan_result_policy_reads
        scan_result_policy_reads.each_batch { |batch| delete_batch(batch) }
      end

      def delete_scan_finding_rules_for_project(project_id)
        approval_project_rules.where(project_id: project_id).each_batch { |batch| delete_batch(batch) }
        approval_merge_request_rules
          .joins(:merge_request)
          .where(merge_request: { target_project_id: project_id })
          .each_batch { |batch| delete_batch(batch) }
      end

      def active_scan_result_policies
        scan_result_policies&.select { |config| config[:enabled] }&.first(LIMIT)
      end

      def scan_result_policies
        policy_by_type(:scan_result_policy)
      end

      def delete_batch(batch)
        batch.delete_all
      end
    end
  end
end
