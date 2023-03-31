# frozen_string_literal: true

module EE
  module Feature
    extend ActiveSupport::Concern

    class_methods do
      extend ::Gitlab::Utils::Override

      override :register_feature_groups
      def register_feature_groups
        super

        Flipper.register(:gitlab_team_members) { |actor| ::Gitlab::Com.gitlab_com_group_member?(actor.thing) }
      end
    end

    module ActiveSupportCacheStoreAdapter
      extend ::Gitlab::Utils::Override

      override :remove
      def remove(key)
        super.tap do |result|
          log_geo_event(key) if result
        end
      end

      override :clear
      def clear(key)
        super.tap do |result|
          log_geo_event(key) if result
        end
      end

      override :enable
      def enable(key, *_)
        super.tap do |result|
          log_geo_event(key) if result
        end
      end

      override :disable
      def disable(key, *_)
        super.tap do |result|
          log_geo_event(key) if result
        end
      end

      private

      def log_geo_event(key)
        ::Geo::CacheInvalidationEventStore.new(key_for(key)).create!
      end
    end
  end
end
