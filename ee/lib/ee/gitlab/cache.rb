# frozen_string_literal: true

module EE
  module Gitlab
    module Cache
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        # Utility to `Rails.cache.delete` *and* propagate to Geo secondaries.
        override :delete
        def delete(key)
          super.tap do
            delete_on_geo_secondaries(key)
          end
        end

        def delete_on_geo_secondaries(key)
          ::Geo::CacheInvalidationEventStore.new(key).create!
        end
      end
    end
  end
end
