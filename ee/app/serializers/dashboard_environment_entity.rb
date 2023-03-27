# frozen_string_literal: true

class DashboardEnvironmentEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :name
  expose :environment_path do |environment|
    project_environment_path(environment.project, environment)
  end

  expose :external_url

  expose :last_visible_deployment, as: :last_deployment, if: ->(environment) { environment.last_visible_deployment } do |environment|
    DeploymentEntity.represent(
      environment.last_visible_deployment,
      options.merge(request: request_with_project, except: unnecessary_deployment_fields)
    )
  end

  expose :last_visible_pipeline, as: :last_pipeline, if: ->(environment) { environment.last_visible_pipeline } do |environment|
    PipelineDetailsEntity.represent(
      environment.last_visible_pipeline,
      options.merge(request: request_with_project, only: required_pipeline_fields)
    )
  end

  private

  alias_method :environment, :object

  def request_with_project
    EntityRequest.new(
      current_user: request.current_user,
      project: environment.project
    )
  end

  def unnecessary_deployment_fields
    [:deployed_by, :manual_actions, :scheduled_actions, :cluster]
  end

  def required_pipeline_fields
    [
      :id,
      { details: :detailed_status },
      { triggered_by: { details: :detailed_status } },
      { triggered: { details: :detailed_status } }
    ]
  end
end
