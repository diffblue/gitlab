# frozen_string_literal: true

module Gitlab
  module Graphql
    module Aggregations
      module Issues
        class LazyBlockAggregate
          include ::Gitlab::Graphql::Deferred

          attr_reader :issue_id, :lazy_state

          def initialize(query_ctx, issue_id, &block)
            @issue_id = issue_id
            @block = block

            # Initialize the loading state for this query,
            # or get the previously-initiated state
            @lazy_state = query_ctx[:lazy_block_aggregate] ||= {
              pending_ids: Set.new,
              loaded_objects: {}
            }
            # Register this ID to be loaded later:
            @lazy_state[:pending_ids] << issue_id
          end

          # Return the loaded record, hitting the database if needed
          def block_aggregate
            # Check if the record was already loaded
            if @lazy_state[:pending_ids].present?
              load_records_into_loaded_objects
            end

            result = @lazy_state[:loaded_objects][@issue_id]

            return @block.call(result) if @block

            result
          end

          alias_method :execute, :block_aggregate

          private

          def load_records_into_loaded_objects
            # The record hasn't been loaded yet, so
            # hit the database with all pending IDs to prevent N+1
            pending_ids = @lazy_state[:pending_ids].to_a
            blocked_data = IssueLink.blocked_issuables_for_collection(pending_ids).compact.flatten

            blocked_data.each do |blocked|
              @lazy_state[:loaded_objects][blocked.blocked_issue_id] = blocked.count
            end

            @lazy_state[:pending_ids].clear
          end
        end
      end
    end
  end
end
