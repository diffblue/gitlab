# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class ClusterImageScanning < Common
          private

          def create_location(location_data)
            ::Gitlab::Ci::Reports::Security::Locations::ClusterImageScanning.new(
              image: location_data['image'],
              cluster_id: location_data.dig('kubernetes_resource', 'cluster_id'),
              agent_id: location_data.dig('kubernetes_resource', 'agent_id'),
              operating_system: location_data['operating_system'],
              package_name: location_data.dig('dependency', 'package', 'name'),
              package_version: location_data.dig('dependency', 'version'))
          end
        end
      end
    end
  end
end
