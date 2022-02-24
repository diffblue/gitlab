# frozen_string_literal: true

# ComplianceManagement::MergeRequests::ComplianceViolationsFinder
#
# Used by the API to filter Compliance Violation records created from merge requests merged within a group
#
# Arguments:
#   current_user: the current user to validate they have the right permissions to access the compliance violations data
#   group_id: the ID of the group to search within

module ComplianceManagement
  module MergeRequests
    class ComplianceViolationsFinder
      include FinderMethods
      include MergedAtFilter

      def initialize(current_user:, group:)
        @current_user = current_user
        @group = group
      end

      def execute
        return ::MergeRequests::ComplianceViolation.none unless allowed?

        ::MergeRequests::ComplianceViolation.by_group(group).order_by_severity_level(:desc)
      end

      private

      attr_reader :current_user, :group

      def allowed?
        ::Feature.enabled?(:compliance_violations_graphql_type, group, default_enabled: :yaml) &&
          Ability.allowed?(current_user, :read_group_compliance_dashboard, group)
      end
    end
  end
end
