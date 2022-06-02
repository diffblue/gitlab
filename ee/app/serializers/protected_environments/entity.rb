# frozen_string_literal: true

module ProtectedEnvironments
  class Entity < Grape::Entity
    expose :id
    expose :project_id
    expose :name
    expose :group_id
    expose :deploy_access_levels, using: ProtectedEnvironments::DeployAccessLevelEntity
  end
end
