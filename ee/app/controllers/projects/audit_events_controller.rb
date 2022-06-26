# frozen_string_literal: true

class Projects::AuditEventsController < Projects::ApplicationController
  include SecurityAndCompliancePermissions
  include Gitlab::Utils::StrongMemoize
  include LicenseHelper
  include AuditEvents::EnforcesValidDateParams
  include AuditEvents::AuditLogsParams
  include AuditEvents::Sortable
  include AuditEvents::DateRange

  before_action :check_audit_events_available!

  feature_category :audit_events

  urgency :low

  def index
    @is_last_page = events.last_page?
    @events = AuditEventSerializer.new.represent(events)

    Gitlab::Tracking.event(self.class.name, 'search_audit_event', user: current_user, project: project, namespace: project.namespace)
  end

  private

  def check_audit_events_available!
    render_404 unless can?(current_user, :read_project_audit_events, project) &&
      (project.feature_available?(:audit_events) || LicenseHelper.show_promotions?(current_user))
  end

  def events
    strong_memoize(:events) do
      level = Gitlab::Audit::Levels::Project.new(project: project)
      events = AuditEventFinder
        .new(level: level, params: audit_params)
        .execute
        .page(params[:page])
        .without_count

      Gitlab::Audit::Events::Preloader.preload!(events)
    end
  end

  def filter_by_author(params)
    return params if can?(current_user, :admin_project, project) || current_user.auditor?

    params.merge(author_id: current_user.id)
  end
end
