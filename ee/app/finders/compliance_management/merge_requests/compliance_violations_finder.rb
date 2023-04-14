# frozen_string_literal: true

# ComplianceManagement::MergeRequests::ComplianceViolationsFinder
#
# Used by the API to filter Compliance Violation records created from merge requests merged within a group
#
# Arguments:
#   current_user: the current user to validate they have the right permissions to access the compliance violations data
#   group_id: the ID of the group to search within
#   params: optional! a hash with one or more of the following:
#     project_ids: restrict the compliance violations returned to those in the group's projects that also match these IDs
#     merged_before: only return compliance violations  which were caused by a merge request merged on or before this date
#     merged_after: only return compliance violations which were caused by a merge request merged on or after this date
#     sort: return compliance violations ordered by severity level, violation reason, merge request title or date merged (asc/desc)

module ComplianceManagement
  module MergeRequests
    class ComplianceViolationsFinder
      include FinderMethods
      include MergedAtFilter

      def initialize(current_user:, group:, params: {})
        @current_user = current_user
        @group = group
        @params = params
      end

      def execute
        return unless allowed?

        Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder.new(
          scope: in_operator_scope,
          array_scope: array_scope,
          array_mapping_scope: ::MergeRequests::ComplianceViolation.method(:in_optimization_array_mapping_scope),
          finder_query: ::MergeRequests::ComplianceViolation.method(:in_optimization_finder_query)
        ).execute
      end

      private

      attr_reader :current_user, :group, :params

      def array_scope
        if params[:project_ids].present?
          group.all_projects.id_in(params[:project_ids]).select(:id)
        else
          group.all_projects.select(:id)
        end
      end

      def in_operator_scope
        base_scope = ::MergeRequests::ComplianceViolation.with_violating_user

        base_scope = base_scope.merged_before(params[:merged_before].end_of_day) if params[:merged_before].present?

        base_scope = base_scope.merged_after(params[:merged_after].beginning_of_day) if params[:merged_after].present?

        base_scope = base_scope.by_target_branch(params[:target_branch]) if params[:target_branch].present?

        base_scope.sort_by_attribute(params[:sort])
      end

      def allowed?
        Ability.allowed?(current_user, :read_group_compliance_dashboard, group)
      end
    end
  end
end
