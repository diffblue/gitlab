# frozen_string_literal: true

module Gitlab
  module Search
    class IndexCurator
      # Reference: https://docs.gitlab.com/ee/integration/advanced_search/elasticsearch.html#tuning

      DEFAULT_SETTINGS = {
        dry_run: true,
        debug: false,
        force: false,
        max_shard_size_gb: Rails.env.production? ? 50 : 1,
        max_docs_denominator: Rails.env.production? ? 5_000_000 : 100,
        min_docs_before_rollover: Rails.env.production? ? 100_000 : 50,
        max_docs_shard_count: 5,
        ignore_patterns: [/migrations/],
        include_patterns: [],
        index_pattern: "gitlab-#{Rails.env}*"
      }.freeze

      attr_reader :settings

      def self.curate(settings = {})
        curator = new(settings)
        curator.curate!
      end

      def initialize(settings = {})
        @settings = validate_settings!(DEFAULT_SETTINGS.merge(settings))
      end

      def curate!
        preflight_checks!

        [].tap do |done_items|
          todo.each do |rollover_info|
            rollover_index(rollover_info) unless settings[:dry_run]

            logger.info(
              log_labels.merge(
                message: "Search curator rolled over an index",
                class: self.class.name,
                dry_run: settings[:dry_run],
                from: rollover_info[:from],
                to: rollover_info[:to],
                reasons: rollover_info[:reasons]
              )
            )

            done_items << rollover_info
          end
        end
      end

      def todo
        [].tap do |todo_list|
          write_indices.each do |index_info|
            next if should_skip_rollover?(index_info)

            reasons = collect_rollover_reasons(index_info)
            next unless reasons.present?

            old_index_name = index_info.fetch('index')
            new_index_name = increment_index_name(old_index_name)

            todo_list << {
              from: old_index_name,
              to: new_index_name,
              reasons: reasons,
              info: index_info
            }
          end
        end
      end

      def should_skip_rollover?(index_info)
        return false if forced?

        should_ignore_index?(index_info) || too_few_docs?(index_info)
      end

      def collect_rollover_reasons(index_info)
        [].tap do |reasons|
          reasons << "too many docs" if too_many_docs?(index_info)
          reasons << "primary shard size too big" if primary_shard_size_too_big?(index_info)
          reasons << "rollover forced" if forced?
        end
      end

      def rollover_index(rollover_info)
        old_index_name = rollover_info[:from]
        new_index_name = rollover_info[:to]

        create_new_index_with_same_settings(old_index: old_index_name, new_index: new_index_name)
        update_aliases(old_index: old_index_name, new_index: new_index_name)
      end

      def increment_index_name(index_name)
        # Increments the number from last four digits of index name
        if index_name.match?(/\A.*\d{4}$/)
          index_num = index_name[-4..].to_i
          index_name[0...-4] + (index_num + 1).to_s.rjust(4, "0")
        else # Otherwise, start next index with number suffix
          "#{index_name}-0002"
        end
      end

      def too_many_docs?(index_info)
        doc_saturation = index_info['docs.count'].to_i / settings[:max_docs_denominator]
        doc_saturation + settings[:max_docs_shard_count] > index_info['pri'].to_i
      end

      def too_few_docs?(index_info)
        index_info['docs.count'].to_i < settings[:min_docs_before_rollover]
      end

      def primary_shard_size_too_big?(index_info)
        index_info['pri.store.size'].to_f > settings[:max_shard_size_gb]
      end

      def should_ignore_index?(index_info)
        return false if settings[:include_patterns].any? { |p| p.match? index_info['index'] }

        settings[:ignore_patterns].any? { |p| p.match? index_info['index'] }
      end

      def forced?
        settings[:force]
      end

      def read_indices
        indices(lifecycle: :read)
      end

      def write_indices
        indices(lifecycle: :write)
      end

      def indices(lifecycle: :all)
        aliases = case lifecycle
                  when :write then fetch_aliases(is_write_index: true)
                  when :read  then fetch_aliases(is_write_index: false)
                  when :all   then fetch_aliases(is_write_index: nil)
                  else
                    raise ArgumentError, "Acceptable lifecycle values are ':write', ':read', or ':all'"
                  end

        return [] unless aliases.present?

        index_names = aliases.filter { |hsh| !should_ignore_index?(hsh) }.map { |hsh| hsh['index'] }

        client.cat.indices(index: index_names, expand_wildcards: 'open', format: 'json', pri: true, bytes: 'gb')
      end

      def client
        @client ||= ::Gitlab::Search::Client.new
      end

      def preflight_checks!
        errors = []

        errors << "migration is pending" if pending_migrations?
        errors << "indexing is paused" if helper.indexing_paused?

        return unless errors.present?

        raise ArgumentError, "preflight checks failed: #{errors.join(', ')}"
      end

      private

      def pending_migrations?
        Feature.enabled?(:elastic_migration_worker, type: :ops) && helper.pending_migrations?
      end

      def validate_settings!(settings)
        raise ArgumentError, 'max_docs_denominator must be greater than 0' if settings[:max_docs_denominator] <= 0

        settings.each_key do |key|
          next if DEFAULT_SETTINGS.has_key? key

          raise ArgumentError, "Invalid setting: `#{key}`. Valid options are `#{DEFAULT_SETTINGS.keys.sort}`"
        end

        settings
      end

      def create_new_index_with_same_settings(old_index:, new_index:)
        index_settings = client.indices.get_settings(index: old_index).dig(old_index, 'settings')
        index_settings['index'] = index_settings['index'].except('uuid', 'version', 'creation_date', 'provided_name')
        index_mappings = client.indices.get_mapping(index: old_index).dig(old_index, 'mappings')

        create_index(name: new_index, settings: index_settings, mappings: index_mappings)
      end

      def update_aliases(old_index:, new_index:)
        # Because we only have one alias for right now, we can just use the first alias for this index
        alias_info = get_alias_info(old_index).dig(old_index, 'aliases')
        raise ArgumentError, "Multiple aliases detected for index: #{old_index}" if alias_info.length > 1

        alias_name = alias_info.each_key.first

        client.indices.update_aliases(
          body: {
            actions: [
              { add: { index: old_index, alias: alias_name, is_write_index: false } },
              { add: { index: new_index, alias: alias_name, is_write_index: true } }
            ]
          }
        )
      end

      def fetch_aliases(is_write_index: nil)
        aliases = client.cat.aliases(name: settings[:index_pattern], format: 'json')

        return aliases if is_write_index.nil?

        if is_write_index
          aliases.filter! { |hsh| %w[true -].include?(hsh['is_write_index']) }
        else
          aliases.filter! { |hsh| %w[false -].include?(hsh['is_write_index']) }
        end

        aliases
      end

      def get_alias_info(pattern)
        helper.get_alias_info(pattern)
      end

      def create_index(name:, settings:, mappings:)
        helper.create_index(
          index_name: name, alias_name: :alias_noop, with_alias: false, settings: settings, mappings: mappings
        )
      end

      def helper
        @helper ||= ::Gitlab::Elastic::Helper.new(client: client)
      end

      def log_labels
        {
          message: "Search curation",
          class: self.class.name
        }
      end

      def logger
        @logger ||= settings[:debug] ? ::Logger.new($stdout) : ::Gitlab::Elasticsearch::Logger.build
      end
    end
  end
end
