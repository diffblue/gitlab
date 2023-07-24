# frozen_string_literal: true

module EE
  module Namespace
    module RootStorageStatistics
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      class_methods do
        extend ::Gitlab::Utils::Override

        override :namespace_statistics_attributes
        def namespace_statistics_attributes
          super << 'wiki_size'
        end
      end

      def cost_factored_storage_size
        (storage_size - forks_size_reduction).round
      end

      private

      def forks_size_reduction
        total = public_forks_storage_size + internal_forks_storage_size
        total += private_forks_storage_size if namespace.paid?

        total * inverted_cost_factor_for_forks
      end

      def inverted_cost_factor_for_forks
        ::Namespaces::Storage::CostFactor.inverted_cost_factor_for_forks(namespace)
      end

      override :from_namespace_statistics
      def from_namespace_statistics
        super.select(
          'COALESCE(SUM(ns.wiki_size), 0) AS wiki_size'
        )
      end
    end
  end
end
