# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      def self.sync_partitions(partitioned_models = default_partitioned_models)
        MultiDatabasePartitionManager.new(partitioned_models).sync_partitions
      end

      def self.default_partitioned_models
        @default_partitioned_models ||= core_partitioned_models.union(ee_partitioned_models)
      end

      def self.core_partitioned_models
        @core_partitioned_models ||= Set[
          ::AuditEvent,
          ::WebHookLog
        ].freeze
      end

      def self.ee_partitioned_models
        return Set.new.freeze unless Gitlab.ee?

        @ee_partitioned_models ||= Set[
          ::IncidentManagement::PendingEscalations::Alert,
          ::IncidentManagement::PendingEscalations::Issue
        ].freeze
      end
    end
  end
end
