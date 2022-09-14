# frozen_string_literal: true

module EE
  module Projects
    module ClusterAgentsController
      extend ActiveSupport::Concern

      prepended do
        before_action do
          push_licensed_feature(:kubernetes_cluster_vulnerabilities, project)
          push_licensed_feature(:cluster_agents_ci_impersonation, project)
        end
      end
    end
  end
end
