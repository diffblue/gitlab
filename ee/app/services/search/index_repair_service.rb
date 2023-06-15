# frozen_string_literal: true

module Search
  class IndexRepairService < BaseProjectService
    include ::Gitlab::Loggable

    DELAY_INTERVAL = 5.minutes

    def self.execute(project)
      new(project: project).execute
    end

    def execute
      return unless Feature.enabled?(:search_index_integrity)
      return unless project.should_check_index_integrity?

      repair_index_for_blobs if should_repair_index_for_blobs?

      repair_index_for_project if project_missing?
    end

    private

    def project_missing?
      query = {
        query: {
          bool: {
            filter: [
              { term: { type: 'project' } },
              { term: { id: project.id } }
            ]
          }
        }
      }

      project_count = client.count(index: index_name, routing: project.es_id, body: query)['count']
      project_count == 0
    end

    def repair_index_for_project
      logger.warn(
        build_structured_payload(
          message: 'project document missing from index',
          namespace_id: project.namespace_id,
          root_namespace_id: project.root_namespace.id,
          project_id: project.id
        )
      )

      ::Elastic::ProcessBookkeepingService.track!(project)
    end

    def repair_index_for_blobs
      ElasticCommitIndexerWorker.perform_in(rand(DELAY_INTERVAL), project.id, false, { force: true })
    end

    def blobs_missing?
      query = {
        query: {
          bool: {
            filter: [
              { term: { type: 'blob' } },
              { term: { project_id: project.id } }
            ]
          }
        }
      }
      blob_count = client.count(index: index_name, routing: project.es_id, body: query)['count']
      (blob_count == 0).tap do |result|
        if result
          logger.warn(
            build_structured_payload(
              message: 'blob documents missing from index for project',
              namespace_id: project.namespace_id,
              root_namespace_id: project.root_namespace.id,
              project_id: project.id,
              project_last_repository_updated_at: project.last_repository_updated_at,
              index_status_last_commit: project.index_status&.last_commit,
              index_status_indexed_at: project.index_status&.indexed_at,
              repository_size: project.statistics&.repository_size
            )
          )
        end
      end
    end

    def should_repair_index_for_blobs?
      return false unless blobs_missing?
      return true if project.index_status.blank?

      project.index_status.last_commit != project.commit.sha
    end

    def client
      @client ||= ::Gitlab::Search::Client.new
    end

    def logger
      @logger ||= ::Gitlab::Elasticsearch::Logger.build
    end

    def index_name
      Repository.__elasticsearch__.index_name
    end
  end
end
