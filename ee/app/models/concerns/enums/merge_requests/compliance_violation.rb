# frozen_string_literal: true

module Enums
  module MergeRequests
    module ComplianceViolation
      # Reasons are defined by GitLab in our public documentation.
      # https://docs.gitlab.com/ee/user/compliance/compliance_dashboard/#separation-of-duties
      def self.reasons
        {
          ::Gitlab::ComplianceManagement::Violations::ApprovedByMergeRequestAuthor::REASON => 0,
          ::Gitlab::ComplianceManagement::Violations::ApprovedByCommitter::REASON => 1,
          ::Gitlab::ComplianceManagement::Violations::ApprovedByInsufficientUsers::REASON => 2
        }.freeze
      end

      def self.severity_levels
        {
          info: 0,
          low: 1,
          medium: 2,
          high: 3,
          critical: 4
        }.freeze
      end
    end
  end
end
