# frozen_string_literal: true

module Projects
  class DependenciesController < Projects::ApplicationController
    include SecurityAndCompliancePermissions

    before_action do
      push_frontend_feature_flag(:sbom_survey, @user, default_enabled: :yaml)
    end

    before_action :authorize_read_dependency_list!

    feature_category :dependency_scanning

    def index
      respond_to do |format|
        format.html do
          render status: :ok
        end
        format.json do
          render json: serializer.represent(dependencies, build: report_service.build)
        end
      end
    end

    private

    def can_access_vulnerable?
      return true unless query_params[:filter] == 'vulnerable'

      can?(current_user, :read_security_resource, project)
    end

    def can_collect_dependencies?
      report_service.able_to_fetch? && can_access_vulnerable?
    end

    def collect_dependencies
      found_dependencies = can_collect_dependencies? ? service.execute : []
      ::Gitlab::ItemsCollection.new(found_dependencies)
    end

    def authorize_read_dependency_list!
      return if can?(current_user, :read_dependencies, project)

      respond_to do |format|
        format.html do
          render_404
        end
        format.json do
          render_403
        end
      end
    end

    def dependencies
      @dependencies ||= collect_dependencies
    end

    def match_disallowed(param, value)
      param == :sort_by && !value.in?(::Security::DependencyListService::SORT_BY_VALUES) ||
        param == :sort && !value.in?(::Security::DependencyListService::SORT_VALUES) ||
        param == :filter && !value.in?(::Security::DependencyListService::FILTER_VALUES)
    end

    def pipeline
      @pipeline ||= report_service.pipeline
    end

    def query_params
      return @permitted_params if @permitted_params

      @permitted_params = params.permit(:sort, :sort_by, :filter).delete_if do |key, value|
        match_disallowed(key, value)
      end
    end

    def report_service
      @report_service ||= ::Security::ReportFetchService.new(project, ::Ci::JobArtifact.dependency_list_reports)
    end

    def serializer
      serializer = ::DependencyListSerializer.new(project: project, user: current_user)
      serializer = serializer.with_pagination(request, response) if params[:page]
      serializer
    end

    def service
      ::Security::DependencyListService.new(pipeline: pipeline, params: query_params)
    end
  end
end
