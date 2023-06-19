# frozen_string_literal: true

# Concern for pausing/unpausing elasticsearch indexing workers
module Elastic
  module IndexingControl
    WORKERS = [ElasticCommitIndexerWorker, ElasticDeleteProjectWorker, ElasticWikiIndexerWorker,
      Search::Wiki::ElasticDeleteGroupWikiWorker].freeze

    def perform(*args)
      if Elastic::IndexingControl.non_cached_pause_indexing? && WORKERS.include?(self.class)
        logger.info(
          message: 'elasticsearch_pause_indexing setting is enabled. Job was added to the waiting queue',
          worker_class: self.class.name,
          args: args
        )
        Elastic::IndexingControlService.add_to_waiting_queue!(self.class, args, current_context)
      else
        super
      end
    end

    class << self
      def non_cached_pause_indexing?
        ApplicationSetting.where(elasticsearch_pause_indexing: true).exists? # rubocop: disable CodeReuse/ActiveRecord
      end

      def resume_processing!
        return false if non_cached_pause_indexing?

        WORKERS.each do |worker_class|
          resume_processing_for(worker_class)
        end

        true
      end

      def resume_processing_for(klass)
        return unless Elastic::IndexingControlService.has_jobs_in_waiting_queue?(klass)

        Elastic::IndexingControlService.resume_processing!(klass)
      end

      def logger
        ::Gitlab::Elasticsearch::Logger.build
      end
    end

    private

    def logger
      Elastic::IndexingControl.logger
    end

    def current_context
      Gitlab::ApplicationContext.current
    end
  end
end
