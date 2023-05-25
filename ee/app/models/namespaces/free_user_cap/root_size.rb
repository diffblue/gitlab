# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class RootSize < Namespaces::Storage::RootSize
      extend ::Gitlab::Utils::Override

      LIMIT_CACHE_NAME = 'free_user_cap_storage_size_limit'

      private

      override :valid_enforcement?
      def valid_enforcement?
        Feature.disabled?(:free_user_cap_without_storage_check)
      end

      override :enforceable_storage_limit
      def enforceable_storage_limit
        root_namespace.actual_limits.storage_size_limit
      end

      override :limit_cache_name
      def limit_cache_name
        LIMIT_CACHE_NAME
      end
    end
  end
end
