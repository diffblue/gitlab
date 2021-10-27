# frozen_string_literal: true

module API
  class ResourceWeightEvents < ::API::Base
    include PaginationParams
    helpers ::API::Helpers::NotesHelpers

    before { authenticate! }

    feature_category :team_planning

    params do
      requires :id, type: String, desc: "The ID of a project"
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc "Get a list of issue resource weight events" do
        success EE::API::Entities::ResourceWeightEvent
      end
      params do
        requires :eventable_id, types: [Integer, String], desc: 'The ID of the eventable'
        use :pagination
      end

      get ":id/issues/:eventable_id/resource_weight_events" do
        eventable = find_noteable(Issue, params[:eventable_id])

        events = if Ability.allowed?(current_user, :read_issue, eventable)
                   eventable.resource_weight_events
                 else
                   ResourceWeightEvent.none
                 end

        present paginate(events), with: EE::API::Entities::ResourceWeightEvent
      end

      desc "Get a single issue resource weight event" do
        success EE::API::Entities::ResourceWeightEvent
      end
      params do
        requires :event_id, type: String, desc: 'The ID of a resource weight event'
        requires :eventable_id, types: [Integer, String], desc: 'The ID of the eventable'
      end
      get ":id/issues/:eventable_id/resource_weight_events/:event_id" do
        eventable = find_noteable(Issue, params[:eventable_id])

        event = eventable.resource_weight_events.find(params[:event_id])

        not_found!('ResourceWeightEvent') unless can?(current_user, :read_issue, event.issue)

        present event, with: EE::API::Entities::ResourceWeightEvent
      end
    end
  end
end
