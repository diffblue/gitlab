# frozen_string_literal: true

module Search
  class ProjectIndexIntegrityWorker
    include ApplicationWorker

    data_consistency :delayed

    feature_category :global_search
    deduplicate :until_executed
    idempotent!
    urgency :throttled

    def perform(project_id)
      return if Feature.disabled?(:search_index_integrity)
      return if project_id.blank?

      project = Project.find_by_id(project_id)

      if project.nil?
        logger.warn(structured_payload(message: 'project not found', project_id: project_id))
        return
      end

      ::Search::IndexRepairService.execute(project)
    end

    def logger
      @logger ||= ::Gitlab::Elasticsearch::Logger.build
    end
  end
end
