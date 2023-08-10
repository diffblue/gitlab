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
      self.reactive_cache_worker_finder = ->(id, *_args) { from_cache(id) }

      def initialize(project, provider, identifier_external_id, language = nil)
        @project = project
        @provider = provider
        @identifier_external_id = identifier_external_id
        @language = language
        @external_type, @external_id, @identifier = identifier_external_id[1..-2].split(']-[')
      end

      def execute
        return unless external_type.in? allowed_identifier_list

        if response_url.nil?
          { name: provider.name, url: response_url, status: "pending" }
        elsif response_url[:url]
          { name: provider.name, url: response_url[:url], status: "completed", identifier: @identifier }
        end
      end

      def self.from_cache(id)
        project_id, provider_id, identifier_external_id, language = id.split('--')

        project = Project.find(project_id)
        provider = ::Security::TrainingProvider.find(provider_id)

        new(project, provider, identifier_external_id, language)
      end

      def query_string
        raise NotImplementedError, 'query_string must be overwritten to return training url query string'
      end

      def full_url
        Gitlab::Utils.append_path(provider.url, query_string)
      end

      def language_param
        "&language=#{@language}" if @language
      end

      private

      attr_reader :project,
        :provider,
        :identifier_external_id,
        :language,
        :external_id,
        :external_type,
        :identifier

      def response_url
        strong_memoize(:response_url) do
          with_reactive_cache(full_url) { |data| data }
        end
      end

      # Required for ReactiveCaching; Usage overridden by
      # self.reactive_cache_worker_finder
      def id
        "#{project.id}--#{provider.id}--#{identifier_external_id}#{language_id_suffix}"
      end

      def language_id_suffix
        "--#{@language}" if @language
      end

      def allowed_identifier_list
        raise NotImplementedError, 'allowed_identifier_list must be overwritten to return allowed identifier list'
      end
    end
  end
end
