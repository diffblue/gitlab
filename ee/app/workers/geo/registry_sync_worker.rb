# frozen_string_literal: true

module Geo
  class RegistrySyncWorker < Geo::Scheduler::Secondary::SchedulerWorker
    include Geo::BaseRegistrySyncWorker

    idempotent!

    private

    def max_capacity
      current_node.files_max_capacity
    end

    def replicator_classes
      Gitlab::Geo.blob_replicator_classes
    end
  end
end
