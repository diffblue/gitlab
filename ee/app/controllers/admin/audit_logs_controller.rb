# frozen_string_literal: true

class Admin::AuditLogsController < Admin::ApplicationController
  include Gitlab::Utils::StrongMemoize
  include AuditEvents::EnforcesValidDateParams
  include AuditEvents::AuditLogsParams
  include AuditEvents::Sortable
  include AuditEvents::DateRange
  include Gitlab::Tracking
  include RedisTracking

  before_action :check_license_admin_audit_log_available!

  track_redis_hll_event :index, name: 'i_compliance_audit_events'

  feature_category :audit_events

  PER_PAGE = 25

  def index
    @is_last_page = events.last_page?
    @events = AuditEventSerializer.new.represent(events)

    @entity = case audit_logs_params[:entity_type]
              when 'User'
                User.find_by_id(audit_logs_params[:entity_id])
              when 'Project'
                Project.find_by_id(audit_logs_params[:entity_id])
              when 'Group'
                Namespace.find_by_id(audit_logs_params[:entity_id])
              else
                nil
              end

    Gitlab::Tracking.event(self.class.name, 'search_audit_event', user: current_user)
  end

  private

  def events
    strong_memoize(:events) do
      level = Gitlab::Audit::Levels::Instance.new
      events = AuditLogFinder
        .new(level: level, params: audit_logs_params)
        .execute
        .page(params[:page])
        .per(PER_PAGE)
        .without_count

      Gitlab::Audit::Events::Preloader.preload!(events)
    end
  end

  def check_license_admin_audit_log_available!
    render_404 unless License.feature_available?(:admin_audit_log)
  end
end
