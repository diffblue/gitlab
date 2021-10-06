# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        module Locations
          class ClusterImageScanning < ContainerScanning
            attr_reader :cluster_id

            def initialize(image:, operating_system:, package_name: nil, package_version: nil, cluster_id: nil)
              super(
                image: image,
                operating_system: operating_system,
                package_name: package_name,
                package_version: package_version
              )
              @cluster_id = cluster_id
            end
          end
        end
      end
    end
  end
end
