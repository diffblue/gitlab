# frozen_string_literal: true

module EE
  module Clusters
    module Agent
      extend ActiveSupport::Concern

      prepended do
        has_many :vulnerability_reads, class_name: 'Vulnerabilities::Read', foreign_key: :casted_cluster_agent_id

        has_many :workspaces,
          class_name: 'RemoteDevelopment::Workspace',
          foreign_key: 'cluster_agent_id',
          inverse_of: :agent

        has_one :remote_development_agent_config,
          class_name: 'RemoteDevelopment::RemoteDevelopmentAgentConfig',
          inverse_of: :agent,
          foreign_key: :cluster_agent_id

        scope :for_projects, -> (projects) { where(project: projects) }
      end
    end
  end
end
