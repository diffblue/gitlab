# frozen_string_literal: true

module EE
  module Gitlab
    module Database
      module Connection
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        override :read_only?
        def read_only?
          ::Gitlab::Geo.secondary? || ::Gitlab.maintenance_mode?
        end

        def healthy?
          !Postgresql::ReplicationSlot.lag_too_great?
        end

        def geo_uncached_queries(&block)
          raise 'No block given' unless block_given?

          scope.uncached do
            if ::Gitlab::Geo.secondary?
              Geo::TrackingBase.uncached(&block)
            else
              yield
            end
          end
        end
      end
    end
  end
end
