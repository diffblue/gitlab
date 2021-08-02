# frozen_string_literal: true

module EE
  module Gitlab
    module Database
      module Connection
        extend ActiveSupport::Concern

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
