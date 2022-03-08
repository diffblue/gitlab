# frozen_string_literal: true

module Security
  module TrainingProviders
    class BaseUrlFinder
      include Gitlab::Utils::StrongMemoize
      include ReactiveCaching

      self.reactive_cache_refresh_interval = 1.minute
      self.reactive_cache_lifetime = 10.minutes
      self.reactive_cache_work_type = :external_dependency
      self.reactive_cache_key = ->(finder) { finder.full_url }
      self.reactive_cache_worker_finder = ->(id, *args) { from_cache(id) }

      def initialize(provider, identifier)
        @provider = provider
        @identifier = identifier
      end

      def execute
        if response_url.nil?
          { name: provider.name, url: response_url, status: "pending" }
        else
          { name: provider.name, url: response_url[:url], status: "completed" } if response_url[:url]
        end
      end

      def self.from_cache(id)
        project_id, provider_id, identifier_id = id.split('-')

        project = Project.find(project_id)
        provider = ::Security::TrainingProvider.find(provider_id)
        identifier = project.vulnerability_identifiers.find(identifier_id)

        new(provider, identifier)
      end

      private

      attr_reader :provider, :identifier

      def response_url
        strong_memoize(:response_url) do
          with_reactive_cache(full_url) {|data| data}
        end
      end

      def full_url
        raise NotImplementedError, 'full_url must be overwritten to return training url'
      end

      # Required for ReactiveCaching; Usage overridden by
      # self.reactive_cache_worker_finder
      def id
        "#{identifier.project.id}-#{provider.id}-#{identifier.id}"
      end
    end
  end
end
