# frozen_string_literal: true

module Gitlab
  module Search
    class IndexCurator
      # Reference: https://docs.gitlab.com/ee/integration/advanced_search/elasticsearch.html#tuning

      DEFAULT_SETTINGS = {
        max_shard_size_gb: 50,
        max_docs_denominator: 5_000_000,
        min_docs_before_rollover: 100_000,
        max_docs_shard_count: 5,
        ignore_patterns: [/migrations/],
        index_pattern: 'gitlab*'
      }.freeze

      attr_reader :settings

      def self.curate(settings = {})
        curator = new(settings)
        curator.preflight_checks!

        [].tap do |rolled_over_indices|
          curator.indices.each do |index_info|
            next unless curator.should_rollover?(index_info)

            rolled_over_indices << curator.rollover_index(index_info)
          end
        end
      rescue StandardError => err
        curator.log_exception(err)
      end

      def initialize(settings = {})
        @settings = validate_settings!(DEFAULT_SETTINGS.merge(settings))
      end

      def rollover_index(index_info)
        old_index_name = index_info.fetch('index')
        new_index_name = increment_index_name(old_index_name)

        { from: old_index_name, to: new_index_name }.tap do |rollover_info|
          if settings[:dry_run]
            logger.info(
              log_labels.merge(message: "[DRY RUN]: would have rolled over => #{rollover_info}")
            )
          else
            create_new_index_with_same_settings(old_index: old_index_name, new_index: new_index_name)
            update_aliases(old_index: old_index_name, new_index: new_index_name)
          end
        end
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

      def should_rollover?(index_info)
        return false if should_ignore_index?(index_info) || too_few_docs?(index_info)

        reasons = []
        reasons << "too many docs" if too_many_docs?(index_info)
        reasons << "primary shard size too big" if primary_shard_size_too_big?(index_info)

        if reasons.present?
          logger.info(
            log_labels.merge(
              message: "Search curator rollover triggered",
              class: self.class.name,
              index: index_info['index'],
              reasons: reasons
            )
          )
          true
        else
          false
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
        settings[:ignore_patterns].any? { |p| p.match? index_info['index'] }
      end

      def indices
        # We only care about the write indices for purposes of curation
        aliases = client.cat.aliases(name: settings[:index_pattern], format: 'json')
                        .filter { |hsh| hsh['is_write_index'] == 'true' || hsh['is_write_index'] == '-' }

        return [] unless aliases.present?

        index_names = aliases.map { |hsh| hsh['index'] }
        client.cat.indices(index: index_names, expand_wildcards: 'open', format: 'json', pri: true, bytes: 'gb')
      end

      def client
        @client ||= ::Gitlab::Search::Client.new
      end

      def preflight_checks!
        errors = []

        errors << "migration is pending" if helper.pending_migrations?
        errors << "indexing is paused" if helper.indexing_paused?

        return unless errors.present?

        raise ArgumentError, "preflight checks failed: #{errors.join(', ')}"
      end

      def log_exception(error)
        logger.error(log_labels.merge(search_curation_status: "error", error: error.message))
      end

      private

      def validate_settings!(settings)
        raise ArgumentError, 'max_docs_denominator must be greater than 0' if settings[:max_docs_denominator] <= 0

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
        alias_name = get_alias_info(old_index).dig(old_index, 'aliases').each_key.first

        client.indices.update_aliases(
          body: {
            actions: [
              { add: { index: old_index, alias: alias_name, is_write_index: false } },
              { add: { index: new_index, alias: alias_name, is_write_index: true } }
            ]
          }
        )
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
        @logger ||= ::Gitlab::Elasticsearch::Logger.build
      end
    end
  end
end
