# frozen_string_literal: true

class Admin::AuditLogsController < Admin::ApplicationController
  include Gitlab::Utils::StrongMemoize
  include AuditEvents::EnforcesValidDateParams
  include AuditEvents::AuditEventsParams
  include AuditEvents::Sortable
  include AuditEvents::DateRange
  include Gitlab::Tracking
  include ProductAnalyticsTracking

  before_action :check_license_admin_audit_event_available!

  track_event :index,
    name: 'i_compliance_audit_events',
    action: 'visit_instance_compliance_audit_events',
    label: 'redis_hll_counters.compliance.compliance_total_unique_counts_monthly',
    destinations: [:redis_hll, :snowplow]

  feature_category :audit_events

  PER_PAGE = 25

  def index
    @is_last_page = events.last_page?
    @events = AuditEventSerializer.new.represent(events)

    @entity = case audit_events_params[:entity_type]
              when 'User'
                user_entity
              when 'Project'
                Project.find_by_id(audit_events_params[:entity_id])
              when 'Group'
                Namespace.find_by_id(audit_events_params[:entity_id])
              end

    Gitlab::Tracking.event(self.class.name, 'search_audit_event', user: current_user)
  end

  private

  def tracking_namespace_source
    nil
  end

  def tracking_project_source
    nil
  end

  def events
    strong_memoize(:events) do
      level = Gitlab::Audit::Levels::Instance.new
      events = AuditEventFinder
        .new(level: level, params: audit_events_params)
        .execute
        .page(params[:page])
        .per(PER_PAGE)
        .without_count

      Gitlab::Audit::Events::Preloader.preload!(events)
    end
  end

  def check_license_admin_audit_event_available!
    render_404 unless License.feature_available?(:admin_audit_log)
  end

  def user_entity
    if audit_events_params[:entity_username].present?
      return User.find_by_username(audit_events_params[:entity_username])
    end

    User.find_by_id(audit_events_params[:entity_id])
  end
end
