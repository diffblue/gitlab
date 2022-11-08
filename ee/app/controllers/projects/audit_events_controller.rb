# frozen_string_literal: true

class Projects::AuditEventsController < Projects::ApplicationController
  include SecurityAndCompliancePermissions
  include Gitlab::Utils::StrongMemoize
  include LicenseHelper
  include AuditEvents::EnforcesValidDateParams
  include AuditEvents::AuditEventsParams
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

  def can_view_events_from_all_members?(user)
    can?(user, :admin_project, project) || user.auditor?
  end
end
