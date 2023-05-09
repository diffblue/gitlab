# frozen_string_literal: true

module Elastic
  class ProcessInitialBookkeepingService < Elastic::ProcessBookkeepingService
    INDEXED_PROJECT_ASSOCIATIONS = [
      :issues,
      :merge_requests,
      :snippets,
      :notes,
      :milestones
    ].freeze

    class << self
      def redis_set_key(shard_number)
        "elastic:bulk:initial:#{shard_number}:zset"
      end

      def redis_score_key(shard_number)
        "elastic:bulk:initial:#{shard_number}:score"
      end

      def backfill_projects!(*projects)
        track!(*projects)

        projects.each do |project|
          raise ArgumentError, 'This method only accepts Projects' unless project.is_a?(Project)

          maintain_indexed_associations(project, INDEXED_PROJECT_ASSOCIATIONS)

          ElasticCommitIndexerWorker.perform_async(project.id, false, { force: true })

          if Feature.enabled?(:separate_elastic_wiki_indexer_for_project)
            ElasticWikiIndexerWorker.perform_async project.id, project.class.name
          else
            ElasticCommitIndexerWorker.perform_async project.id, true
          end
        end
      end
    end
  end
end
