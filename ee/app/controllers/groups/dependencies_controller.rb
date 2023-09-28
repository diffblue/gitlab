# frozen_string_literal: true

module Groups
  class DependenciesController < Groups::ApplicationController
    include GovernUsageGroupTracking

    before_action :authorize_read_dependency_list!

    feature_category :dependency_management
    urgency :low
    track_govern_activity 'dependencies', :index

    # More details on https://gitlab.com/gitlab-org/gitlab/-/issues/411257#note_1508315283
    GROUP_COUNT_LIMIT = 600

    before_action only: :index do
      push_frontend_feature_flag(:group_level_licenses, group)
      push_frontend_feature_flag(:group_level_dependencies_filtering, group)
    end

    def index
      respond_to do |format|
        format.html do
          set_enable_project_search

          render status: :ok
        end
        format.json do
          render json: dependencies_serializer
            .represent(dependencies_finder.execute)
        end
      end
    end

    def locations
      render json: ::Sbom::DependencyLocationListEntity.represent(
        Sbom::DependencyLocationsFinder.new(
          namespace: group,
          params: params.permit(:component_id, :search)
        ).execute
      )
    end

    private

    def authorize_read_dependency_list!
      return if can?(current_user, :read_dependency, group) && Feature.enabled?(:group_level_dependencies, group)

      render_not_authorized
    end

    def dependencies_finder
      ::Sbom::DependenciesFinder.new(group, params: dependencies_finder_params)
    end

    def dependencies_finder_params
      if Feature.enabled?(:group_level_dependencies_filtering, group) && filtering_allowed?
        params.permit(
          :page,
          :per_page,
          :sort,
          :sort_by,
          component_names: [],
          package_managers: []
        )
      else
        params.permit(:page, :per_page, :sort, :sort_by)
      end
    end

    def dependencies_serializer
      DependencyListSerializer
        .new(project: nil, group: group, user: current_user)
        .with_pagination(request, response)
    end

    def render_not_authorized
      respond_to do |format|
        format.html do
          render_404
        end
        format.json do
          render_403
        end
      end
    end

    def set_enable_project_search
      @enable_project_search = filtering_allowed?
    end

    def filtering_allowed?
      group.count_within_namespaces <= GROUP_COUNT_LIMIT
    end
  end
end
