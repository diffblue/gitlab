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

  def show_filter_for_project?(project)
    can?(current_user, :admin_project, project)
  end

  def show_filter_for_group?(group)
    can?(current_user, :admin_group, group)
  end

  def show_streams_for_group?(group)
    return false if group.subgroup?

    can?(current_user, :admin_external_audit_events, group)
  end

  def show_streams_headers?(group)
    return false unless show_streams_for_group?(group)

    Feature.enabled?(:custom_headers_streaming_audit_events_ui, group)
  end
end
