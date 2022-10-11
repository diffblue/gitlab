# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class Dast < Common
          def parse!
            super

            report.scanned_resources = create_scanned_resources(report_data.dig('scan', 'scanned_resources'))
          end

          private

          def create_scanned_resources(scanned_resources)
            return [] unless scanned_resources

            scanned_resources.map do |sr|
              uri = URI.parse(sr['url'])
              ::Gitlab::Ci::Reports::Security::ScannedResource.new(uri, sr['method'])
            rescue URI::InvalidURIError
              nil
            end.compact
          end

          def create_location(location_data)
            ::Gitlab::Ci::Reports::Security::Locations::Dast.new(
              hostname: location_data['hostname'],
              method_name: location_data['method'],
              param: location_data['param'],
              path: location_data['path'])
          end
        end
      end
    end
  end
end
