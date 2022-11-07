# frozen_string_literal: true

module API
  module Entities
    module ProtectedEnvironments
      class DeployAccessLevel < ProtectedRefAccess
        expose :group_inheritance_type, documentation: { type: 'integer', example: 0 }
      end
    end
  end
end
