# frozen_string_literal: true

class DashboardOperationsProjectEntity < Grape::Entity
  include Gitlab::Utils::StrongMemoize
  include RequestAwareEntity

  expose :project, merge: true, using: API::Entities::BasicProjectDetails

  expose :remove_path do |_|
    remove_operations_project_path(project_id: project.id)
  end

  expose :upgrade_required
  expose :upgrade_path, if: -> (*) { upgrade_required && user_can_upgrade? } do |_|
    project&.group ? group_billings_path(project.group) : profile_billings_path
  end

  expose :last_pipeline, if: -> (*) { !upgrade_required && last_pipeline } do |_, options|
    PipelineDetailsEntity.represent(last_pipeline, options.merge(request: new_request))
  end

  expose :last_deployment, if: -> (*) { !upgrade_required && last_deployment } do |_, options|
    DeploymentEntity.represent(last_deployment, options.merge(request: new_request))
  end

  expose :alert_count, if: -> (*) { !upgrade_required }

  private

  alias_method :dashboard_project, :object

  def new_request
    EntityRequest.new(
      current_user: current_user,
      project: project
    )
  end

  def upgrade_required
    strong_memoize(:upgrade_required) do
      !project.feature_available?(:operations_dashboard)
    end
  end

  def user_can_upgrade?
    can?(current_user, :admin_namespace, project&.namespace)
  end

  def last_pipeline
    project.last_pipeline
  end

  def last_deployment
    dashboard_project.last_deployment
  end

  def current_user
    request.current_user
  end

  def project
    dashboard_project.project
  end
end
