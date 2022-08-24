# frozen_string_literal: true

module EE
  module Clusters
    module Agent
      extend ActiveSupport::Concern

      prepended do
        has_many :vulnerability_reads, class_name: 'Vulnerabilities::Read', foreign_key: :casted_cluster_agent_id

        scope :for_projects, -> (projects) { where(project: projects) }
      end
    end
  end
end
