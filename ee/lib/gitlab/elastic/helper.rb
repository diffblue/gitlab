# frozen_string_literal: true

module Gitlab
  module Elastic
    class Helper
      ES_MAPPINGS_CLASSES = [
        Project,
        MergeRequest,
        Snippet,
        Note,
        Milestone,
        ProjectWiki,
        Repository,
        User
      ].freeze

      ES_SEPARATE_CLASSES = [
        Issue,
        Note,
        MergeRequest,
        Commit,
        User,
        Wiki
      ].freeze

      INDEXED_CLASSES = (ES_SEPARATE_CLASSES + [Repository]).freeze

      attr_reader :version, :client
      attr_accessor :target_name

      def initialize(
        version: ::Elastic::MultiVersionUtil::TARGET_VERSION,
        client: nil,
        target_name: nil)

        proxy = self.class.create_proxy(version)

        @client = client || proxy.client
        @target_name = target_name || proxy.index_name
        @version = version
      end

      class << self
        def create_proxy(version = nil)
          Project.__elasticsearch__.version(version)
        end

        def default
          self.new
        end

        def connection_settings(uri:, user: nil, password: nil)
          # Returns a hash that is compatible with elasticsearch-transport client settings.
          #
          # See:
          # https://github.com/elastic/elasticsearch-ruby/blob/v7.3.0/elasticsearch-transport/lib/elasticsearch/transport/client.rb#L196
          uri = Addressable::URI.parse(uri) if uri.is_a? String

          {
            scheme: uri.scheme,
            user: user.presence || Addressable::URI.unencode(uri.user),
            password: password.presence || Addressable::URI.unencode(uri.password) || (user.present? ? '' : nil),
            host: uri.host,
            path: uri.path,
            port: uri.port
          }.compact
        end

        def url_string(url_settings)
          # Converts the hash from connection_settings into a percent encoded URL string.
          Addressable::URI.new(url_settings).normalize.to_s
        end

        def build_es_id(es_type:, target_id:)
          "#{es_type}_#{target_id}"
        end
      end

      def default_settings
        ES_MAPPINGS_CLASSES.inject({}) do |settings, klass|
          settings.deep_merge(klass.__elasticsearch__.settings.to_hash)
        end
      end

      def default_mappings
        mappings = ES_MAPPINGS_CLASSES.inject({}) do |m, klass|
          m.deep_merge(klass.__elasticsearch__.mappings.to_hash)
        end
        mappings.deep_merge(::Elastic::Latest::CustomLanguageAnalyzers.custom_analyzers_mappings)
      end

      def migrations_index_name
        "#{target_name}-migrations"
      end

      def index_name_with_timestamp(alias_name, suffix: nil)
        "#{alias_name}-#{Time.now.utc.strftime('%Y%m%d-%H%M')}#{suffix}"
      end

      def create_migrations_index
        settings = { number_of_shards: 1 }
        mappings = {
          properties: {
            completed: {
              type: 'boolean'
            },
            state: {
              type: 'object'
            },
            started_at: {
              type: 'date'
            },
            completed_at: {
              type: 'date'
            }
          }
        }

        create_index_options = {
          index: migrations_index_name,
          body: {
            settings: settings.to_hash,
            mappings: mappings.to_hash
          }
        }

        client.indices.create create_index_options

        migrations_index_name
      end

      def pending_migrations?
        ::Elastic::DataMigrationService.pending_migrations.present?
      end

      def indexing_paused?
        ::Gitlab::CurrentSettings.elasticsearch_pause_indexing?
      end

      def delete_migration_record(migration)
        result = client.delete(index: migrations_index_name, type: '_doc', id: migration.version)
        result['result'] == 'deleted'
      rescue ::Elasticsearch::Transport::Transport::Errors::NotFound => e
        Gitlab::ErrorTracking.log_exception(e)
        false
      end

      def standalone_indices_proxies(target_classes: nil)
        classes = if target_classes.present?
                    # Only allow classes from ES_SEPARATE_CLASSES
                    target_classes & ES_SEPARATE_CLASSES
                  else
                    ES_SEPARATE_CLASSES
                  end

        classes.map do |class_name|
          ::Elastic::Latest::ApplicationClassProxy.new(class_name, use_separate_indices: true)
        end
      end

      def create_standalone_indices(with_alias: true, options: {}, target_classes: nil)
        proxies = standalone_indices_proxies(target_classes: target_classes)
        proxies.each_with_object({}) do |proxy, indices|
          alias_name = proxy.index_name
          new_index_name = index_name_with_timestamp(alias_name, suffix: options[:name_suffix])

          create_index(
            index_name: new_index_name,
            alias_name: alias_name,
            with_alias: with_alias,
            settings: proxy.settings.to_hash,
            mappings: proxy.mappings.to_hash,
            options: options
          )
          indices[new_index_name] = alias_name
        end
      end

      def delete_standalone_indices
        standalone_indices_proxies.map do |proxy|
          index_name = target_index_name(target: proxy.index_name)
          result = delete_index(index_name: index_name)

          [index_name, proxy.index_name, result]
        end
      end

      def delete_migrations_index
        delete_index(index_name: migrations_index_name)
      end

      def migrations_index_exists?
        index_exists?(index_name: migrations_index_name)
      end

      def create_empty_index(with_alias: true, options: {})
        new_index_name = options[:index_name] || index_name_with_timestamp(target_name, suffix: options[:name_suffix])

        create_index(
          index_name: new_index_name,
          alias_name: target_name,
          with_alias: with_alias,
          settings: default_settings,
          mappings: default_mappings,
          options: options
        )

        {
          new_index_name => target_name
        }
      end

      def delete_index(index_name: nil)
        result = client.indices.delete(index: target_index_name(target: index_name))
        result['acknowledged']
      rescue ::Elasticsearch::Transport::Transport::Errors::NotFound => e
        Gitlab::ErrorTracking.log_exception(e)
        false
      end

      def index_exists?(index_name: nil)
        client.indices.exists?(index: index_name || target_name) # rubocop:disable CodeReuse/ActiveRecord
      end

      def alias_exists?(name: nil)
        client.indices.exists_alias(name: name || target_name)
      end

      def alias_missing?(name: nil)
        !alias_exists?(name: name)
      end

      # Calls Elasticsearch refresh API to ensure data is searchable
      # immediately.
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-refresh.html
      # By default refreshes main and standalone_indices
      def refresh_index(index_name: nil)
        indices = if index_name.nil?
                    [target_name] + standalone_indices_proxies.map(&:index_name)
                  else
                    [index_name]
                  end

        indices.each do |index|
          # ignore indexes which may not be created yet (for example: pending migrations)
          next unless index_exists?(index_name: index)

          client.indices.refresh(index: index)
        end
      end

      def index_size(index_name: nil)
        index = target_index_name(target: index_name || target_index_name)

        client.indices.stats.dig('indices', index, 'total')
      end

      def documents_count(index_name: nil)
        index = target_index_name(target: index_name || target_index_name)

        client.indices.stats.dig('indices', index, 'primaries', 'docs', 'count')
      end

      def index_size_bytes(index_name: nil)
        index_size(index_name: index_name)['store']['size_in_bytes']
      end

      def cluster_free_size_bytes
        client.cluster.stats['nodes']['fs']['free_in_bytes']
      end

      def reindex(from: target_index_name, to:, max_slice:, slice:, wait_for_completion: false)
        response = ::Search::ReindexingService.execute(
          from: from, to: to, slice: slice, max_slices: max_slice, wait_for_completion: wait_for_completion
        )

        response['task']
      end

      def task_status(task_id:)
        client.tasks.get(task_id: task_id)
      end

      def get_settings(index_name: nil)
        index = target_index_name(target: index_name)
        settings = client.indices.get_settings(index: index)
        settings.dig(index, 'settings', 'index')
      end

      def get_mapping(index_name: nil)
        index = target_index_name(target: index_name)
        mappings = client.indices.get_mapping({ index: index })
        mappings.dig(index, 'mappings', 'properties')
      end

      def update_settings(index_name: nil, settings:)
        client.indices.put_settings(index: index_name || target_index_name, body: settings)
      end

      def update_mapping(index_name: nil, mappings:)
        options = {
          index: index_name || target_index_name,
          body: mappings
        }
        client.indices.put_mapping(options)
      end

      def get_meta(index_name: nil)
        index = target_index_name(target: index_name)
        mappings = client.indices.get_mapping(index: index)
        mappings.dig(index, 'mappings', '_meta')
      end

      def switch_alias(from: target_index_name, alias_name: target_name, to:)
        actions = [
          {
            remove: { index: from, alias: alias_name }
          },
          {
            add: { index: to, alias: alias_name }
          }
        ]

        multi_switch_alias(actions: actions)
      end

      def multi_switch_alias(actions:)
        client.indices.update_aliases(body: { actions: actions })
      end

      # This method is used when we need to get an actual index name (if it's used through an alias)
      def target_index_name(target: nil)
        index_names = target_index_names(target: target)
        index_names.find { |_, write_index| write_index }.first
      end

      # @return [Hash<String, Boolean>] index_name => is_write_index
      def target_index_names(target:)
        target ||= target_name

        if alias_exists?(name: target)
          client.indices.get_alias(name: target).transform_values do |options|
            # If it's not set, that means that this is the write index
            options.dig('aliases', target, 'is_write_index') || true
          end
        else
          { target => true }
        end
      end

      def klass_to_alias_name(klass:)
        return target_name if klass == Repository

        ::Elastic::Latest::ApplicationClassProxy.new(klass, use_separate_indices: true).index_name
      end

      # handles unreachable hosts and any other exceptions that may be raised
      def ping?
        client.ping
      rescue StandardError
        false
      end

      def server_info
        info = client.info.fetch('version', {})

        {
          distribution: info.fetch('distribution', 'elasticsearch'),
          version: info['number'],
          build_type: info['build_type'],
          lucene_version: info['lucene_version']
        }
      rescue StandardError
        {}
      end

      # Tested and supported version/distributions of Elasticsearch/Opensearch
      def supported_version?
        return true unless ping?

        search_check = ::SystemCheck::App::SearchCheck.new
        search_check.skip? || search_check.check?
      end

      # Versions that are known to be unsupported
      def unsupported_version?
        info = server_info

        case info[:distribution]
        when 'elasticsearch'
          Gitlab::VersionInfo.parse(info[:version]).major == 6
        else
          false
        end
      end

      def create_index(index_name:, alias_name:, with_alias:, settings:, mappings:, options: {})
        if index_exists?(index_name: index_name)
          return if options[:skip_if_exists]

          raise "Index under '#{index_name}' already exists."
        end

        if with_alias && index_exists?(index_name: alias_name)
          return if options[:skip_if_exists]

          raise "Index or alias under '#{alias_name}' already exists."
        end

        # Indifferent access avoids issue where there could be duplicate keys
        # where one is a string and another is a symbol
        settings = settings.with_indifferent_access
        mappings = mappings.with_indifferent_access
        settings.merge!(options[:settings]) if options[:settings]
        mappings.merge!(options[:mappings]) if options[:mappings]

        meta_info = {
          _meta: {
            created_by: Gitlab::VERSION
          }.merge(options.fetch(:meta, {}))
        }

        create_index_options = {
          index: index_name,
          body: {
            settings: settings,
            mappings: mappings.deep_merge(meta_info)
          }
        }

        client.indices.create create_index_options
        client.indices.put_alias(name: alias_name, index: index_name) if with_alias
      end

      def get_alias_info(pattern)
        client.indices.get_alias(index: pattern)
      end
    end
  end
end
