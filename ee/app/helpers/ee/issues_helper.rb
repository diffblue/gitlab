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

    override :show_timeline_view_toggle?
    def show_timeline_view_toggle?(issue)
      issue.work_item_type&.incident? && issue.project.feature_available?(:incident_timeline_view)
    end

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
    def issue_header_actions_data(project, issuable, current_user, issuable_sidebar)
      actions = super
      actions[:can_promote_to_epic] = issuable.can_be_promoted_to_epic?(current_user).to_s
      actions
    end

    override :common_issues_list_data
    def common_issues_list_data(namespace, current_user)
      super.merge(
        has_blocked_issues_feature: namespace.feature_available?(:blocked_issues).to_s,
        has_issuable_health_status_feature: namespace.feature_available?(:issuable_health_status).to_s,
        has_issue_weights_feature: namespace.feature_available?(:issue_weights).to_s,
        has_iterations_feature: namespace.feature_available?(:iterations).to_s,
        has_scoped_labels_feature: namespace.feature_available?(:scoped_labels).to_s,
        has_okrs_feature: namespace.feature_available?(:okrs).to_s
      )
    end

    override :project_issues_list_data
    def project_issues_list_data(project, current_user)
      super.tap do |data|
        if project.feature_available?(:epics) && project.group
          data[:group_path] = project.group.full_path
        end
      end
    end

    override :group_issues_list_data
    def group_issues_list_data(group, current_user)
      super.tap do |data|
        data[:can_bulk_update] = (can?(current_user, :admin_issue, group) && group.feature_available?(:group_bulk_edit)).to_s

        if group.feature_available?(:epics)
          data[:group_path] = group.full_path
        end
      end
    end

    override :dashboard_issues_list_data
    def dashboard_issues_list_data(current_user)
      super.merge(
        has_blocked_issues_feature: License.feature_available?(:blocked_issues).to_s,
        has_issuable_health_status_feature: License.feature_available?(:issuable_health_status).to_s,
        has_issue_weights_feature: License.feature_available?(:issue_weights).to_s,
        has_scoped_labels_feature: License.feature_available?(:scoped_labels).to_s
      )
    end
  end
end
