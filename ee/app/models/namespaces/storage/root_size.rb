# frozen_string_literal: true

module Namespaces
  module Storage
    class RootSize
      CURRENT_SIZE_CACHE_KEY = 'root_storage_current_size'
      LIMIT_CACHE_KEY = 'root_storage_size_limit'
      EXPIRATION_TIME = 10.minutes

      def initialize(root_namespace)
        @root_namespace = root_namespace.root_ancestor # just in case the true root isn't passed
      end

      def above_size_limit?
        return false unless valid_enforcement?

        usage_ratio > 1
      end

      def usage_ratio
        return 0 if limit == 0

        current_size.to_f / limit.to_f
      end

      def current_size
        @current_size ||= Rails.cache.fetch(current_size_cache_key, expires_in: EXPIRATION_TIME) do
          root_namespace.root_storage_statistics&.storage_size || 0
        end
      end

      def limit
        @limit ||= Rails.cache.fetch(limit_cache_key, expires_in: EXPIRATION_TIME) do
          root_namespace.actual_limits.storage_size_limit.megabytes +
            root_namespace.additional_purchased_storage_size.megabytes
        end
      end

      def used_storage_percentage
        (usage_ratio * 100).floor
      end

      def remaining_storage_percentage
        [(100 - usage_ratio * 100).floor, 0].max
      end

      def remaining_storage_size
        [limit - current_size, 0].max
      end

      def valid_enforcement?
        return false unless enforce_limit?

        !root_namespace.temporary_storage_increase_enabled?
      end

      def enforce_limit?
        ::Namespaces::Storage::Enforcement.enforce_limit?(root_namespace)
      end

      alias_method :enabled?, :enforce_limit?

      def error_message
        message_params = { namespace_name: root_namespace.name }

        @error_message_object ||=
          ::EE::Gitlab::NamespaceStorageSizeErrorMessage.new(checker: self, message_params: message_params)
      end

      def exceeded_size(change_size = 0)
        size = current_size + change_size - limit

        [size, 0].max
      end

      def changes_will_exceed_size_limit?(change_size)
        limit != 0 && exceeded_size(change_size) > 0
      end

      def enforcement_type
        :namespace_storage_limit
      end

      private

      attr_reader :root_namespace

      delegate :gitlab_subscription, to: :root_namespace

      def current_size_cache_key
        ['namespaces', root_namespace.id, CURRENT_SIZE_CACHE_KEY]
      end

      def limit_cache_key
        ['namespaces', root_namespace.id, LIMIT_CACHE_KEY]
      end
    end
  end
end
