# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountRemoteAgentConfigurationsMetric < DatabaseMetric
          operation :distinct_count, column: :cluster_agent_id

          # TODO: Do we only want to consider agents that have successfully connected?
          relation { RemoteDevelopment::RemoteDevelopmentAgentConfig }

          start { RemoteDevelopment::RemoteDevelopmentAgentConfig.minimum(:cluster_agent_id) }
          finish { RemoteDevelopment::RemoteDevelopmentAgentConfig.maximum(:cluster_agent_id) }
        end
      end
    end
  end
end
