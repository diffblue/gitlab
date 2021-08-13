# frozen_string_literal: true

module EE
  module Gitlab
    module Metrics
      module Samplers
        module DatabaseSampler
          extend ::Gitlab::Utils::Override

          private

          override :host_stats
          def host_stats
            super.concat(geo_connection_stats)
          end

          def geo_connection_stats
            return [] unless ::Geo::TrackingBase.connected?

            [{ labels: labels_for_class(::Geo::TrackingBase), stats: ::Geo::TrackingBase.connection_pool.stat }]
          end
        end
      end
    end
  end
end
