# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      # This class is responsible for loading distinct stage records
      # within the group hierarchy. The stage metadata is uniquely identified
      # by its stage_event_hash_id column. There can be multiple stages with the
      # same metadata (created with different names or within different subgroups).
      #
      # Example:
      #
      # Stage 1 (config: issue_created - issue_closed)
      # Stage 2 (config: issue_created - issue_deployed_to_production)
      # Stage 3 (config: issue_created - issue_closed) # same metadata as #1
      #
      # Expected results:
      #
      # Stage 1, Stage 2
      #
      # The class also adds two "in-memory" stages into the distinct calculation which
      # represent the CycleTime and LeadTime metrics. These metrics are calculated as
      # pre-defined VSA stages.
      class DistinctStageLoader
        def initialize(group:)
          @group = group
        end

        def stages
          [
            *persisted_stages,
            add_stage_event_hash_id(in_memory_lead_time_stage),
            add_stage_event_hash_id(in_memory_cycle_time_stage)
          ].uniq(&:stage_event_hash_id)
        end

        private

        attr_reader :group

        def persisted_stages
          @persisted_stages ||= ::Analytics::CycleAnalytics::Stage.distinct_stages_within_hierarchy(group)
        end

        def in_memory_lead_time_stage
          ::Analytics::CycleAnalytics::Stage.new(
            name: 'lead time', # not visible to the user
            start_event_identifier: Summary::LeadTime.start_event_identifier,
            end_event_identifier: Summary::LeadTime.end_event_identifier,
            namespace: group
          )
        end

        def in_memory_cycle_time_stage
          ::Analytics::CycleAnalytics::Stage.new(
            name: 'cycle time',
            start_event_identifier: Summary::CycleTime.start_event_identifier,
            end_event_identifier: Summary::CycleTime.end_event_identifier,
            namespace: group
          )
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def add_stage_event_hash_id(stage)
          # find or create the stage event hash
          hash_record = ::Analytics::CycleAnalytics::StageEventHash.find_by(hash_sha256: stage.events_hash_code)
          stage.stage_event_hash_id = if hash_record
                                        hash_record.id
                                      else
                                        ::Analytics::CycleAnalytics::StageEventHash.record_id_by_hash_sha256(stage.events_hash_code)
                                      end

          stage
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
