# frozen_string_literal: true

module AuditEvents
  module AuditEventsParams
    SAFE_PARAMS = [:created_before, :created_after, :sort].freeze

    def audit_events_params
      params.permit(*SAFE_PARAMS, :entity_type, :entity_id, :entity_username, :author_id, :author_username)
    end

    def audit_params
      audit_events_params
        .then { |params| transform_author_entity_type(params) }
        .then { |params| filter_by_author(params) }
    end

    # This is an interim change until we have proper API support within Audit Events
    def transform_author_entity_type(params)
      return params unless params[:entity_type] == 'Author'

      params[:author_id] = params[:entity_id]

      params.slice(*SAFE_PARAMS, :author_id, :author_username)
    end

    def filter_by_author(params)
      return params if can_view_events_from_all_members?(current_user)

      # User can only view own events
      params
        .slice(*SAFE_PARAMS)
        .merge(author_id: current_user.id)
    end
  end
end
