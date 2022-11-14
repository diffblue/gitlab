# frozen_string_literal: true

module API
  class ResourceIterationEvents < ::API::Base
    include PaginationParams
    helpers ::API::Helpers::NotesHelpers

    resource_iteration_events_tags = %w[resource_iteration_events]

    before { authenticate! }

    { Issue => :team_planning }.each do |eventable_type, feature_category|
      parent_type = eventable_type.parent_class.to_s.underscore
      eventables_str = eventable_type.to_s.underscore.pluralize

      params do
        requires :id, types: [String, Integer], desc: "The ID or URL-encoded path the #{parent_type}"
      end
      resource parent_type.pluralize.to_sym, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc "Get a list of #{eventable_type.to_s.downcase} resource iteration events" do
          detail 'This feature was introduced in GitLab 13.4'
          success EE::API::Entities::ResourceIterationEvent
          is_array true
          tags resource_iteration_events_tags
        end
        params do
          requires :eventable_id, types: [Integer, String], desc: 'The ID of the eventable'
          use :pagination
        end

        get ":id/#{eventables_str}/:eventable_id/resource_iteration_events", feature_category: feature_category do
          eventable = find_noteable(eventable_type, params[:eventable_id])
          events = eventable.resource_iteration_events.with_api_entity_associations

          present paginate(events), with: EE::API::Entities::ResourceIterationEvent
        end

        desc "Get a single #{eventable_type.to_s.downcase} resource iteration event" do
          detail 'This feature was introduced in GitLab 13.4'
          success EE::API::Entities::ResourceIterationEvent
          tags resource_iteration_events_tags
        end
        params do
          requires :event_id, type: String, desc: 'The ID of a resource iteration event'
          requires :eventable_id, types: [Integer, String], desc: 'The ID of the eventable'
        end
        get ":id/#{eventables_str}/:eventable_id/resource_iteration_events/:event_id", feature_category: feature_category do
          eventable = find_noteable(eventable_type, params[:eventable_id])
          event = eventable.resource_iteration_events.find(params[:event_id])

          present event, with: EE::API::Entities::ResourceIterationEvent
        end
      end
    end
  end
end
