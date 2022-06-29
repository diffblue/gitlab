# frozen_string_literal: true

module API
  class Iterations < ::API::Base
    include PaginationParams

    feature_category :team_planning
    urgency :low

    before do
      adjust_deprecated_state
    end

    helpers do
      include ::API::Helpers::IterationsHelper

      params :list_params do
        optional :state,
          type: String, values: %w[opened upcoming started current closed all],
          default: 'all',
          desc: 'Return "opened", "upcoming", "current (previously started)", "closed", or "all" iterations. ' \
                'Filtering by `started` state is deprecated starting with 14.1, please use `current` instead.',
          documentation: { example: 'opened' }
        optional :search,
          type: String,
          desc: 'The search criteria for the title of the iteration',
          documentation: { example: 'version' }
        optional :include_ancestors,
          type: Grape::API::Boolean,
          default: true,
          desc: 'Include iterations from parent and its ancestors',
          documentation: { example: false }
        optional :updated_before,
          type: DateTime,
          desc: 'Return milestones updated before the specified datetime. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ',
          documentation: { example: '2023-02-28T21:22:12Z' }
        optional :updated_after,
          type: DateTime,
          desc: 'Return milestones updated after the specified datetime. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ',
          documentation: { example: '2023-02-28T21:22:12Z' }
        use :pagination
      end

      def list_iterations_for(parent)
        iterations = IterationsFinder.new(current_user, iterations_finder_params(parent)).execute

        present paginate(iterations), with: Entities::Iteration
      end

      def iterations_finder_params(parent)
        finder_params = {
          parent: parent,
          include_ancestors: params[:include_ancestors],
          state: params[:state],
          search: nil,
          in: nil,
          updated_before: params[:updated_before],
          updated_after: params[:updated_after]
        }

        finder_params.merge!(search_params) if params[:search]

        finder_params
      end

      def search_params
        {
          search: params[:search],
          in: [::Resolvers::IterationsResolver::DEFAULT_IN_FIELD]
        }
      end
    end

    params do
      requires :id,
        types: [String, Integer],
        desc: 'The ID or URL-encoded path of the project',
        documentation: { example: 5 }
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of project iterations' do
        detail 'This feature was introduced in GitLab 13.5'
        success Entities::Iteration
        is_array true
      end
      params do
        use :list_params
      end
      get ":id/iterations" do
        authorize! :read_iteration, user_project

        list_iterations_for(user_project)
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group', documentation: { example: 5 }
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of group iterations' do
        detail 'This feature was introduced in GitLab 13.5'
        success Entities::Iteration
        is_array true
      end
      params do
        use :list_params
      end
      get ":id/iterations" do
        authorize! :read_iteration, user_group

        list_iterations_for(user_group)
      end
    end
  end
end
