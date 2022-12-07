# frozen_string_literal: true

module AuditEventsHelper
  FILTER_TOKEN_TYPES = {
    user: :user,
    group: :group,
    project: :project,
    member: :member
  }.freeze

  def admin_audit_event_tokens
    [
      { type: FILTER_TOKEN_TYPES[:user] },
      { type: FILTER_TOKEN_TYPES[:group] },
      { type: FILTER_TOKEN_TYPES[:project] }
    ].freeze
  end

  def group_audit_event_tokens(group_id)
    [{ type: FILTER_TOKEN_TYPES[:member], group_id: group_id }].freeze
  end

  def project_audit_event_tokens(project_path)
    [{ type: FILTER_TOKEN_TYPES[:member], project_path: project_path }].freeze
  end

  def export_url
    admin_audit_log_reports_url(format: :csv)
  end

  def view_only_own_project_events?(project)
    !can?(current_user, :admin_project, project) && !current_user.auditor?
  end

  def view_only_own_group_events?(group)
    !can?(current_user, :admin_group, group) && !current_user.auditor?
  end

  def filter_view_only_own_events_token_values(view_only)
    return [] unless view_only

    [{ type: FILTER_TOKEN_TYPES[:member], data: "@#{current_user.username}" }]
  end

  def show_streams_for_group?(group)
    return false if group.subgroup?

    can?(current_user, :admin_external_audit_events, group)
  end
end
