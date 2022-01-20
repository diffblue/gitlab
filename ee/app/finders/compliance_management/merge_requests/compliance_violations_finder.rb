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
        return ::MergeRequests::ComplianceViolation.none unless allowed?

        items = init_collection

        items = filter_by_projects(items)
        items = filter_by_merged_before(items)
        items = filter_by_merged_after(items)

        sort(items)
      end

      private

      attr_reader :current_user, :group, :params

      def allowed?
        ::Feature.enabled?(:compliance_violations_graphql_type, group, default_enabled: :yaml) &&
          Ability.allowed?(current_user, :read_group_compliance_dashboard, group)
      end

      def init_collection
        ::MergeRequests::ComplianceViolation.with_violating_user.by_group(group)
      end

      def filter_by_projects(items)
        return items unless params[:project_ids].present?

        items.by_projects(params[:project_ids])
      end

      def filter_by_merged_before(items)
        return items unless params[:merged_before].present?

        items.merged_before(params[:merged_before]) if params[:merged_before].present?
      end

      def filter_by_merged_after(items)
        return items unless params[:merged_after].present?

        items.merged_after(params[:merged_after]) if params[:merged_after].present?
      end

      def sort(items)
        case params[:sort]
        when 'SEVERITY_LEVEL_ASC' then items.order_by_severity_level(:asc)
        when 'SEVERITY_LEVEL_DESC' then items.order_by_severity_level(:desc)
        when 'VIOLATION_REASON_ASC' then items.order_by_reason(:asc)
        when 'VIOLATION_REASON_DESC' then items.order_by_reason(:desc)
        when 'MERGE_REQUEST_TITLE_ASC' then items.order_by_merge_request_title(:asc)
        when 'MERGE_REQUEST_TITLE_DESC' then items.order_by_merge_request_title(:desc)
        when 'MERGED_AT_ASC' then items.order_by_merged_at(:asc)
        when 'MERGED_AT_DESC' then items.order_by_merged_at(:desc)
        else items.order_by_severity_level(:desc)
        end
      end
    end
  end
end
