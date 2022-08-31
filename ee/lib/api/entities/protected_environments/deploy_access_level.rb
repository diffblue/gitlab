# frozen_string_literal: true

module API
  module Entities
    module ProtectedEnvironments
      class DeployAccessLevel < ProtectedRefAccess
        expose :id
        expose :group_inheritance_type
      end
    end
  end
end
