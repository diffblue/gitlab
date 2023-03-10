# frozen_string_literal: true

module Elastic
  class MigrationRecord
    include Gitlab::Loggable

    attr_reader :version, :name, :filename

    ELASTICSEARCH_SIZE = 1000

    def initialize(version:, name:, filename:)
      @version = version
      @name = name
      @filename = filename
      @migration = nil
    end

    def save!(completed:)
      raise 'Migrations index is not found' unless helper.index_exists?(index_name: index_name)

      data = { completed: completed, state: load_state, name: name }.merge(timestamps(completed: completed))

      client.index index: index_name, type: '_doc', id: version, body: data
    end

    def save_state!(state)
      completed = load_from_index&.dig('_source', 'completed')

      client.index index: index_name, refresh: true, type: '_doc', id: version, body: { completed: completed, state: load_state.merge(state) }
    end

    def started?
      load_from_index.present?
    end

    def load_from_index
      client.get(index: index_name, id: version)
    rescue StandardError => e
      logger.error(build_structured_payload(message: "[#{self.class.name}]: #{e.class}: #{e.message}"))
      nil
    end

    def load_state
      load_from_index&.dig('_source', 'state')&.with_indifferent_access || {}
    end

    def halted?
      !!load_state&.dig('halted')
    end

    def failed?
      !!load_state&.dig('failed')
    end

    def previous_attempts
      load_state[:previous_attempts].to_i
    end

    def current_attempt
      previous_attempts + 1
    end

    def halt(additional_options = {})
      state = { halted: true, halted_indexing_unpaused: false }.merge(additional_options)
      save_state!(state)
    end

    def fail(additional_options = {})
      halt(additional_options.merge(failed: true))
    end

    def name_for_key
      name.underscore
    end

    def running?
      started? && !stopped?
    end

    def stopped?
      halted? || completed?
    end

    def method_missing(method, *args, &block)
      if migration.respond_to?(method)
        migration.public_send(method, *args, &block) # rubocop: disable GitlabSecurity/PublicSend
      else
        super
      end
    end

    def self.load_versions(completed:)
      helper = Gitlab::Elastic::Helper.default
      helper.client
            .search(index: helper.migrations_index_name, body: { query: { term: { completed: completed } }, size: ELASTICSEARCH_SIZE })
            .dig('hits', 'hits')
            .map { |v| v['_id'].to_i }
    end

    def self.completed_versions
      load_versions(completed: true)
    end

    def self.current_migration
      completed_migrations = completed_versions

      # use exclude to support new migrations which do not exist in the index yet
      Elastic::DataMigrationService.migrations.find { |migration| completed_migrations.exclude?(migration.version) } # rubocop: disable CodeReuse/ServiceClass
    end

    private

    def timestamps(completed:)
      {}.tap do |data|
        existing_data = load_from_index
        data[:started_at] = existing_data&.dig('_source', 'started_at') || Time.now.utc

        data[:completed_at] = Time.now.utc if completed
      end
    end

    def migration
      @migration ||= load_migration
    end

    def load_migration
      require(File.expand_path(filename))
      name.constantize.new version
    end

    def index_name
      helper.migrations_index_name
    end

    def client
      helper.client
    end

    def helper
      Gitlab::Elastic::Helper.default
    end

    def logger
      @logger ||= ::Gitlab::Elasticsearch::Logger.build
    end
  end
end
