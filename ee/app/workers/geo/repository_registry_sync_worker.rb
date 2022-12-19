# frozen_string_literal: true

module Geo
  class RepositoryRegistrySyncWorker < Geo::Scheduler::Secondary::SchedulerWorker
    include Geo::BaseRegistrySyncWorker

    idempotent!

    private

    def max_capacity
      capacity = [current_node.repos_max_capacity / 10, 1].max

      # Transition-period-solution, see
      # https://gitlab.com/gitlab-org/gitlab/-/issues/372444#note_1087132645c
      capacity += current_node.container_repositories_max_capacity if ::Geo::ContainerRepositoryReplicator.enabled?

      capacity
    end

    def replicator_classes
      Gitlab::Geo.repository_replicator_classes
    end
  end
end
