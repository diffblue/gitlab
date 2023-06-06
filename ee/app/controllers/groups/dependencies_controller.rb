# frozen_string_literal: true

module Groups
  class DependenciesController < Groups::ApplicationController
    before_action :authorize_read_dependency_list!

    feature_category :dependency_management
    urgency :low

    def index
      respond_to do |format|
        format.html do
          render status: :ok
        end
        format.json do
          render json: serialized_dependencies
        end
      end
    end

    private

    def authorize_read_dependency_list!
      return if can?(current_user, :read_dependencies, group) && Feature.enabled?(:group_level_dependencies, group)

      render_not_authorized
    end

    def dependency_list_params
      params.permit(:sort_by, :sort, :page, :per_page, package_managers: [])
    end

    def collect_dependencies
      @collect_dependencies ||= ::Sbom::DependenciesFinder.new(group, params: dependency_list_params).execute
    end

    def serialized_dependencies
      DependencyListEntity.represent(collect_dependencies, entity_request)
    end

    def entity_request
      {
        request: EntityRequest.new(project: nil, user: current_user)
      }
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
  end
end
