# frozen_string_literal: true

module Search
  class NamespaceIndexIntegrityWorker
    include ApplicationWorker
    include Gitlab::ExclusiveLeaseHelpers

    data_consistency :delayed

    feature_category :global_search
    deduplicate :until_executed
    idempotent!
    urgency :throttled

    LEASE_TIMEOUT = 30.minutes.freeze
    PROJECT_DELAY_INTERVAL = 24.hours.freeze
    NAMESPACE_DELAY_INTERVAL = 1.hour.freeze

    def perform(namespace_id)
      return if namespace_id.blank?
      return if Feature.disabled?(:search_index_integrity)

      namespace = Namespace.find_by_id(namespace_id)

      if namespace.nil?
        logger.warn(structured_payload(message: 'namespace not found', namespace_id: namespace_id))
        return
      end

      return unless namespace.use_elasticsearch?

      in_lock("#{self.class.name.underscore}/namespace/#{namespace_id}", ttl: LEASE_TIMEOUT) do
        logger.info(structured_payload(message: 'enqueueing all children for namespace', namespace_id: namespace_id))
        namespace.children.each_batch do |relation|
          relation.each do |n|
            ::Search::NamespaceIndexIntegrityWorker.perform_in(rand(NAMESPACE_DELAY_INTERVAL).seconds, n.id)
          end
        end

        logger.info(structured_payload(message: 'enqueueing all projects for namespace', namespace_id: namespace_id))
        namespace.projects.each_batch do |relation|
          relation.each do |project|
            next unless project.should_check_index_integrity?

            ::Search::ProjectIndexIntegrityWorker.perform_in(rand(PROJECT_DELAY_INTERVAL).seconds, project.id)
          end
        end
      end
    end

    private

    def logger
      @logger ||= ::Gitlab::Elasticsearch::Logger.build
    end
  end
end
