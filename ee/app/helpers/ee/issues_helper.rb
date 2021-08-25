# frozen_string_literal: true

module EE
  module IssuesHelper
    extend ::Gitlab::Utils::Override

    def issue_in_subepic?(issue, epic_id)
      # This helper is used if a list of issues are filtered by epic id
      return false if epic_id.blank?
      return false if %w(any none).include?(epic_id)
      return false if issue.epic_issue.nil?

      # An issue is member of a subepic when its epic id is different
      # than the filter epic id on params
      epic_id.to_i != issue.epic_issue.epic_id
    end

    def show_timeline_view_toggle?(issue)
      issue.incident? && issue.project.feature_available?(:incident_timeline_view)
    end

    # OVERRIDES

    override :scoped_labels_available?
    def scoped_labels_available?(parent)
      parent.feature_available?(:scoped_labels)
    end

    override :issue_closed_link
    def issue_closed_link(issue, current_user, css_class: '')
      if issue.promoted? && can?(current_user, :read_epic, issue.promoted_to_epic)
        link_to(s_('IssuableStatus|promoted'), issue.promoted_to_epic, class: css_class)
      else
        super
      end
    end

    override :issue_header_actions_data
    def issue_header_actions_data(project, issuable, current_user)
      actions = super
      actions[:can_promote_to_epic] = issuable.can_be_promoted_to_epic?(current_user).to_s
      actions
    end

    override :issues_list_data
    def issues_list_data(project, current_user, finder)
      data = super.merge!(
        has_blocked_issues_feature: project.feature_available?(:blocked_issues).to_s,
        has_issuable_health_status_feature: project.feature_available?(:issuable_health_status).to_s,
        has_issue_weights_feature: project.feature_available?(:issue_weights).to_s,
        has_iterations_feature: project.feature_available?(:iterations).to_s,
        has_multiple_issue_assignees_feature: project.feature_available?(:multiple_issue_assignees).to_s
      )

      if project.feature_available?(:epics) && project.group
        data[:group_epics_path] = group_epics_path(project.group, format: :json)
      end

      data
    end

    override :group_issues_list_data
    def group_issues_list_data(group, current_user, issues)
      data = super.merge!(
        can_bulk_update: (can?(current_user, :admin_issue, group) && group.feature_available?(:group_bulk_edit)).to_s,
        has_blocked_issues_feature: group.feature_available?(:blocked_issues).to_s,
        has_issuable_health_status_feature: group.feature_available?(:issuable_health_status).to_s,
        has_issue_weights_feature: group.feature_available?(:issue_weights).to_s,
        has_iterations_feature: group.feature_available?(:iterations).to_s,
        has_multiple_issue_assignees_feature: group.feature_available?(:multiple_issue_assignees).to_s
      )

      if group.feature_available?(:epics)
        data[:group_epics_path] = group_epics_path(group, format: :json)
      end

      data
    end
  end
end
