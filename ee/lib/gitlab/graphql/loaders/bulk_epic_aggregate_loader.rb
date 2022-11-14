# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      class BulkEpicAggregateLoader
        include ::Gitlab::Graphql::Aggregations::Epics::Constants

        MAXIMUM_LOADABLE = 100_001
        EPIC_BATCH_SIZE = 1000

        attr_reader :target_epic_ids, :results, :count_health_status

        # This class retrieves each epic and its child epics recursively
        # It allows us to recreate the epic tree structure in POROs
        def initialize(epic_ids:, count_health_status: false)
          @results = {}
          @target_epic_ids = epic_ids
          @count_health_status = count_health_status
        end

        def execute
          return {} unless target_epic_ids

          # the list of epics and epic decendants is intentionally loaded
          # separately, the reason is that if number of epic_ids is over some
          # limit (~200), then postgres uses a slow query plan and first does
          # left join of epic_issues with issues which times out
          epic_ids = ::Epic.ids_for_base_and_decendants(target_epic_ids)
          raise ArgumentError, "There are too many epics to load. Please select fewer epics or contact your administrator." if epic_ids.count >= MAXIMUM_LOADABLE

          # We do a left outer join in order to capture epics with no issues
          # This is so we can aggregate the epic counts for every epic
          raw_results = []
          epic_ids.in_groups_of(EPIC_BATCH_SIZE).each do |epic_batch_ids|
            raw_results += ::Epic.issue_metadata_for_epics(epic_ids: epic_batch_ids, limit: MAXIMUM_LOADABLE, count_health_status: count_health_status)
            raise ArgumentError, "There are too many records to load. Please select fewer epics or contact your administrator." if raw_results.count >= MAXIMUM_LOADABLE
          end

          @results = raw_results.group_by { |record| record[:id] }
        end
      end
    end
  end
end
