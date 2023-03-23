# frozen_string_literal: true

module Search
  class IndexRegistry
    DEFAULT_CACHE_DURATION = 1.minute

    class << self
      def index_for_namespace(namespace:, type:)
        with_cache(:index_pattern_for_namespace, namespace.id, type.name) do
          type.route(hash: namespace.hashed_root_namespace_id).tap do |index|
            ::Search::NamespaceIndexAssignment.assign_index(namespace: namespace, index: index)
          end
        end
      end

      private

      def with_cache(*args, expires_in: DEFAULT_CACHE_DURATION, &blk)
        cache_backend.fetch([name] + args, expires_in: expires_in, &blk)
      end

      def cache_backend
        Gitlab::ProcessMemoryCache.cache_backend
      end
    end
  end
end
