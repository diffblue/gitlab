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

      private

      override :from_namespace_statistics
      def from_namespace_statistics
        super.select(
          'COALESCE(SUM(ns.wiki_size), 0) AS wiki_size'
        )
      end
    end
  end
end
