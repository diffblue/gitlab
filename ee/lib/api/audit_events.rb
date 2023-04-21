# frozen_string_literal: true

module API
  class AuditEvents < ::API::Base
    include ::API::PaginationParams

    urgency :low

    feature_category :audit_events

    before do
      authenticated_as_admin!
      forbidden! unless ::License.feature_available?(:admin_audit_log)
      increment_unique_values('a_compliance_audit_events_api', current_user.id)

      ::Gitlab::Tracking.event(
        'API::AuditEvents',
        :admin_audit_event_request,
        user: current_user,
        context: [::Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: 'a_compliance_audit_events_api').to_context]
      )
    end

    resources :audit_events do
      desc 'Get the list of audit events' do
        success EE::API::Entities::AuditEvent
        is_array true
      end
      params do
        optional :entity_type, type: String, desc: 'Return list of audit events for the specified entity type', values: AuditEventFinder::VALID_ENTITY_TYPES
        optional :entity_id, type: Integer
        given :entity_id do
          requires :entity_type, type: String
        end
        optional :created_after,
          type: DateTime,
          desc: 'Return audit events created after the specified time',
          documentation: { type: 'dateTime', example: '2016-01-19T09:05:50.355Z' }
        optional :created_before,
          type: DateTime,
          desc: 'Return audit events created before the specified time',
          documentation: { type: 'dateTime', example: '2016-01-19T09:05:50.355Z' }

        use :pagination
      end
      get do
        level = ::Gitlab::Audit::Levels::Instance.new
        audit_events = AuditEventFinder.new(level: level, params: params).execute

        present paginate_with_strategies(audit_events), with: EE::API::Entities::AuditEvent
      end

      desc 'Get single audit event' do
        success EE::API::Entities::AuditEvent
      end
      params do
        requires :id, type: Integer, desc: 'The ID of audit event'
      end
      get ':id' do
        level = ::Gitlab::Audit::Levels::Instance.new
        # rubocop: disable CodeReuse/ActiveRecord
        # This is not `find_by!` from ActiveRecord
        audit_event = AuditEventFinder.new(level: level).find(params[:id])
        # rubocop: enable CodeReuse/ActiveRecord

        present audit_event, with: EE::API::Entities::AuditEvent
      end
    end
  end
end
