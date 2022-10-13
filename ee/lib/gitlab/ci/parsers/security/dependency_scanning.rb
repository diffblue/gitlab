# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class DependencyScanning < Common
          private

          def create_location(location_data)
            ::Gitlab::Ci::Reports::Security::Locations::DependencyScanning.new(
              file_path: location_data['file'],
              package_name: location_data.dig('dependency', 'package', 'name'),
              package_version: location_data.dig('dependency', 'version'))
          end
        end
      end
    end
  end
end
