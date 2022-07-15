# frozen_string_literal: true

module AuditEvents
  module AuditEventsParams
    def audit_events_params
      params.permit(:entity_type, :entity_id, :created_before, :created_after, :sort, :author_id, :entity_username, :author_username)
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

      params.except(:entity_type, :entity_id)
    end
  end
end
