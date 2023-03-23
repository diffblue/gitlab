# frozen_string_literal: true

module Gitlab
  module Search
    class Client
      DELEGATED_METHODS = %i[cat count indices index reindex update_by_query search].freeze

      attr_reader :adapter

      def initialize(adapter: nil)
        @adapter = adapter || default_adapter
      end

      delegate(*DELEGATED_METHODS, to: :adapter)

      private

      def default_adapter
        # Note: in the future, the default adapter should be changed to whatever
        # adapter is compatible with the version of search engine that is being used
        # in GitLab's application settings.
        ::Gitlab::Elastic::Helper.default.client
      end
    end
  end
end
