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
      delegate :approval_rules, to: :project

      def active_scan_result_policies
        return [] unless ::Feature.enabled?(:scan_result_policy, project)

        scan_result_policies&.select { |config| config[:enabled] }&.first(LIMIT)
      end

      def scan_result_policies
        policy_by_type(:scan_result_policy)
      end

      def uniq_scanners
        distinct_scanners = approval_rules.distinct_scanners
        return [] if distinct_scanners.none?

        distinct_scanners.pluck(:scanners).flatten.uniq
      end
    end
  end
end
