# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        module Locations
          class ClusterImageScanning < ContainerScanning
            attr_reader :cluster_id, :agent_id

            def initialize(image:, operating_system:, package_name: nil, package_version: nil, cluster_id: nil, agent_id: nil)
              super(
                image: image,
                operating_system: operating_system,
                package_name: package_name,
                package_version: package_version
              )
              @cluster_id = cluster_id
              @agent_id = agent_id
            end

            def fingerprint_data
              return super if agent_id.blank?

              "AGENT_#{agent_id}:#{super}"
            end
          end
        end
      end
    end
  end
end
