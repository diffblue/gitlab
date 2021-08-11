# frozen_string_literal: true

class DashboardEnvironmentsProjectEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :name
  expose :avatar_url
  expose :web_url

  expose :remove_path do |project|
    remove_operations_environments_project_path(project_id: project.id)
  end

  expose :namespace, using: API::Entities::NamespaceBasic
  expose :environments_for_dashboard, as: :environments, using: DashboardEnvironmentEntity
end
