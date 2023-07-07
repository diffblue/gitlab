# frozen_string_literal: true

module Gitlab
  module Security
    module Orchestration
      class ProjectPolicyConfigurations
        def initialize(project)
          @project = project
        end

        def all
          ::Gitlab::SafeRequestStore.fetch("security-orchestration-policies:#{@project.id}") do
            uncached_all
          end
        end

        private

        def uncached_all
          return [] unless @project.licensed_feature_available?(:security_orchestration_policies)

          @project.all_security_orchestration_policy_configurations
        end
      end
    end
  end
end
