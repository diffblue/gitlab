# frozen_string_literal: true

module Search
  class IndexRegistry
    DEFAULT_CACHE_DURATION = 1.minute

    def self.index_for_namespace(namespace:, type:)
      new(namespace: namespace, type: type).index
    end

    attr_reader :namespace, :type

    def initialize(namespace:, type:)
      @namespace = namespace
      @type = type
      @cache_key = cache_key
    end

    def index
      type.new(fetch_index_attrs)
    end

    private

    def fetch_index_attrs
      cache_backend.fetch(cache_key, expires_in: DEFAULT_CACHE_DURATION) do
        fetch_index_from_db.as_json
      end
    end

    def cache_backend
      Gitlab::ProcessMemoryCache.cache_backend
    end

    def cache_key
      [self.class.name, :index_for_namespace, namespace.id, type.name]
    end

    def fetch_index_from_db
      fetch_assigned_index || assign_index
    end

    def fetch_assigned_index
      type.joins(:namespace_index_assignments)
        .find_by(namespace_index_assignments: { namespace_id: namespace.id, index_type: type.name })
    end

    def assign_index
      type.route(hash: namespace.hashed_root_namespace_id).tap do |idx|
        ::Search::NamespaceIndexAssignment.assign_index(namespace: namespace, index: idx)
      end
    end
  end
end
