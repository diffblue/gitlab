# frozen_string_literal: true

module Gitlab
  module Graphql
    module Aggregations
      module Issuables
        class LazyBlockAggregate
          include ::Gitlab::Graphql::Deferred

          attr_reader :issuable_id, :lazy_state

          def initialize(query_ctx, issuable_id, &block)
            @issuable_id = issuable_id
            @block = block

            # Initialize the loading state for this query,
            # or get the previously-initiated state
            @lazy_state = query_ctx[:lazy_block_aggregate] ||= {
              pending_ids: Set.new,
              loaded_objects: {}
            }
            # Register this ID to be loaded later:
            @lazy_state[:pending_ids] << issuable_id
          end

          # Return the loaded record, hitting the database if needed
          def block_aggregate
            # Check if the record was already loaded
            if @lazy_state[:pending_ids].present?
              load_records_into_loaded_objects
            end

            result = @lazy_state[:loaded_objects][@issuable_id]

            return @block.call(result) if @block

            result
          end

          alias_method :execute, :block_aggregate

          private

          def link_class
            raise NotImplementedError
          end

          def issuable_type
            link_class.issuable_type
          end

          def load_records_into_loaded_objects
            # The record hasn't been loaded yet, so
            # hit the database with all pending IDs to prevent N+1
            grouped_ids_row = "blocked_#{issuable_type}_id"
            pending_ids = @lazy_state[:pending_ids].to_a
            blocked_data = link_class.blocked_issuables_for_collection(pending_ids).compact.flatten

            blocked_data.each do |blocked|
              issuable_id = blocked[grouped_ids_row]
              @lazy_state[:loaded_objects][issuable_id] = blocked.count
            end

            @lazy_state[:pending_ids].clear
          end
        end
      end
    end
  end
end
