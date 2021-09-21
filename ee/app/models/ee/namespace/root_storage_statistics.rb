# frozen_string_literal: true

module EE
  module Namespace
    module RootStorageStatistics
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        NAMESPACE_STATISTICS_ATTRIBUTES = %w[storage_size wiki_size].freeze
      end

      override :merged_attributes
      def merged_attributes
        super.merge!(attributes_from_namespace_statistics) { |key, v1, v2| v1 + v2 }
      end

      private

      def attributes_from_namespace_statistics
        # At the moment, only groups can have some storage data because of group wikis.
        # Therefore, if the namespace is not a group one, there is no need to perform
        # the query. If this changes in the future and we add some sort of resource to
        # users that it's store in NamespaceStatistics, we will need to remove this
        # guard clause.
        return {} unless namespace.group_namespace?

        from_namespace_statistics.take.slice(*NAMESPACE_STATISTICS_ATTRIBUTES)
      end

      def from_namespace_statistics
        namespace
          .self_and_descendants
          .joins("INNER JOIN namespace_statistics ns ON ns.namespace_id  = namespaces.id")
          .select(
            'COALESCE(SUM(ns.storage_size), 0) AS storage_size',
            'COALESCE(SUM(ns.wiki_size), 0) AS wiki_size'
          )
      end
    end
  end
end
