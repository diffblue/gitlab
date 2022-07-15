# frozen_string_literal: true

class Groups::AuditEventsController < Groups::ApplicationController
  include Gitlab::Utils::StrongMemoize
  include AuditEvents::EnforcesValidDateParams
  include AuditEvents::AuditEventsParams
  include AuditEvents::Sortable
  include AuditEvents::DateRange
  include RedisTracking

  before_action :check_audit_events_available!

  track_redis_hll_event :index, name: 'g_compliance_audit_events'

  feature_category :audit_events

  urgency :low

  def index
    @is_last_page = events.last_page?
    @events = AuditEventSerializer.new.represent(events)

    Gitlab::Tracking.event(self.class.name, 'search_audit_event', user: current_user, namespace: group)
  end

  private

  def check_audit_events_available!
    render_404 unless can?(current_user, :read_group_audit_events, group) &&
      group.licensed_feature_available?(:audit_events)
  end

  def events
    strong_memoize(:events) do
      level = Gitlab::Audit::Levels::Group.new(group: group)
      events = AuditEventFinder
        .new(level: level, params: audit_params)
        .execute
        .page(params[:page])
        .without_count

      Gitlab::Audit::Events::Preloader.preload!(events)
    end
  end

  def filter_by_author(params)
    return params if can?(current_user, :admin_group, group) || current_user.auditor?

    params.merge(author_id: current_user.id)
  end
end
