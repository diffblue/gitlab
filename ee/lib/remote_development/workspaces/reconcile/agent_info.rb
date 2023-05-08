# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Reconcile
      class AgentInfo
        attr_reader :name, :namespace, :actual_state, :deployment_resource_version

        def initialize(name:, namespace:, actual_state:, deployment_resource_version:)
          @name = name
          @namespace = namespace
          @actual_state = actual_state
          @deployment_resource_version = deployment_resource_version
        end

        def ==(other)
          return false unless other && self.class == other.class

          other.name == name &&
            other.namespace == namespace &&
            other.actual_state == actual_state &&
            other.deployment_resource_version == deployment_resource_version
        end
      end
    end
  end
end
