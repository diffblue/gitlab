# frozen_string_literal: true

module ProtectedEnvironments
  class DeployAccessLevelEntity < Grape::Entity
    expose :id
    expose :access_level
    expose :protected_environment_id
    expose :user_id
    expose :group_id
    expose :group_inheritance_type
  end
end
