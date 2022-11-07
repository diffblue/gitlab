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

    def perform
      return unless Feature.enabled?(:search_index_curation)

      in_lock(self.class.name.underscore, ttl: 10.minutes, retries: 10, sleep_sec: 1) do
        ::Gitlab::Search::IndexCurator.curate.each do |rolled_over_index|
          logger.info("Rollover: #{rolled_over_index[:from]} => #{rolled_over_index[:to]}")
        end
      end
    rescue StandardError => e
      logger.error("#{self.class.name}: #{e.class} #{e.message}")
    rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
      # We're scheduled on a cronjob, so nothing to do here
    end

    private

    def logger
      @logger ||= ::Gitlab::Elasticsearch::Logger.build
    end
  end
end
