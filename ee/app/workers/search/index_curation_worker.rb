# frozen_string_literal: true

module Search
  class IndexCurationWorker
    include ApplicationWorker
    include Gitlab::ExclusiveLeaseHelpers

    data_consistency :always

    # There is no onward scheduling and this cron handles work from across the
    # application, so there's no useful context to add.
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
    include ActionView::Helpers::NumberHelper

    feature_category :global_search
    idempotent!
    urgency :throttled

    attr_accessor :curator_settings

    def initialize(*)
      super

      @curator_settings = {
        dry_run: Feature.enabled?(:search_curation_dry_run, type: :ops),
        ignore_patterns: [/.*/],
        include_patterns: curation_include_patterns,
        max_shard_size_gb: ::Gitlab::CurrentSettings.search_max_shard_size_gb,
        max_docs_denominator: ::Gitlab::CurrentSettings.search_max_docs_denominator,
        min_docs_before_rollover: ::Gitlab::CurrentSettings.search_min_docs_before_rollover
      }
    end

    def perform
      return unless Feature.enabled?(:search_index_curation)

      in_lock(self.class.name.underscore, ttl: 10.minutes, retries: 10, sleep_sec: 1) do
        ::Gitlab::Search::IndexCurator.curate(curator_settings).each do |rolled_over_index|
          logger.info("Rollover: #{rolled_over_index[:from]} => #{rolled_over_index[:to]}")
        end
      end
    rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
      # We're scheduled on a cronjob, so nothing to do here
    rescue StandardError => e
      logger.error("#{self.class.name}: #{e.class} #{e.message}")
    end

    private

    def curation_include_patterns
      [].tap do |patterns|
        separate_index_types.each do |index_type|
          patterns << /#{index_type}/ if Feature.enabled?("search_index_curation_#{index_type}", type: :ops)
        end

        patterns << main_index_pattern if Feature.enabled?(:search_index_curation_main_index, type: :ops)
      end
    end

    def main_index_pattern
      helper = ::Gitlab::Elastic::Helper.default
      write_index_name = helper.target_index_name(target: helper.target_name)
      write_index_prefix = write_index_name.slice(0, write_index_name.length - 4) # Everything but auto increment number
      /#{write_index_prefix}/
    end

    def separate_index_types
      ::Gitlab::Elastic::Helper::ES_SEPARATE_CLASSES.map { |c| c.to_s.underscore.pluralize }
    end

    def logger
      @logger ||= ::Gitlab::Elasticsearch::Logger.build
    end
  end
end
