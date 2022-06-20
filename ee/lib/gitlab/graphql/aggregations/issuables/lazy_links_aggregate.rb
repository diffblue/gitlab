# frozen_string_literal: true

module Gitlab
  module Graphql
    module Aggregations
      module Issuables
        class LazyLinksAggregate
          include ::Gitlab::Graphql::Deferred

          attr_reader :issuable_id, :lazy_state, :link_type

          def initialize(query_ctx, issuable_id, link_type: :blocked, &block)
            @issuable_id = issuable_id
            @link_type = link_type.to_s
            @block = block

            # Initialize the loading state for this query,
            # or get the previously-initiated state
            @lazy_state = query_ctx[:lazy_links_aggregate] ||= {
              pending_ids: { 'blocked' => Set.new, 'blocking' => Set.new },
              loaded_objects: { 'blocked' => {}, 'blocking' => {} }
            }

            # Register this ID to be loaded later:
            @lazy_state[:pending_ids][@link_type] << issuable_id
          end

          # Return the loaded record, hitting the database if needed
          def links_aggregate
            # Check if the record was already loaded
            if @lazy_state[:pending_ids][link_type].present?
              load_records_into_loaded_objects
            end

            result = @lazy_state[:loaded_objects][link_type][@issuable_id]

            return @block.call(result) if @block

            result
          end

          alias_method :execute, :links_aggregate

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
            grouped_ids_row = "#{link_type}_#{issuable_type}_id"
            pending_ids = @lazy_state[:pending_ids][link_type].to_a
            builder = link_class.method("#{link_type}_issuables_for_collection")
            data = builder.call(pending_ids).compact.flatten

            data.each do |row|
              issuable_id = row[grouped_ids_row]
              @lazy_state[:loaded_objects][link_type][issuable_id] = row.count
            end

            @lazy_state[:pending_ids][link_type].clear
          end
        end
      end
    end
  end
end
