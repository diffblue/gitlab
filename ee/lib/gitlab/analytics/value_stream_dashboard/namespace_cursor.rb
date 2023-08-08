# frozen_string_literal: true

module Gitlab
  module Analytics
    module ValueStreamDashboard
      class NamespaceCursor
        NAMESPACE_BATCH_SIZE = 300

        def initialize(namespace_class:, inner_namespace_query:, cursor_data:)
          @namespace_class = namespace_class
          @inner_namespace_query = inner_namespace_query
          @cursor_data = cursor_data
          @top_level_namespace_id = cursor_data.fetch(:top_level_namespace_id)
        end

        def next
          enumerator.next.tap do |namespace|
            cursor_data[:namespace_id] = namespace.id
          end
        rescue StopIteration
          nil
        end

        def [](key)
          cursor_data[key]
        end

        def update(**data)
          @cursor_data.merge!(data)
        end

        def dump
          cursor_data
        end

        private

        attr_reader :namespace_class, :inner_namespace_query, :cursor_data, :top_level_namespace_id

        # rubocop: disable CodeReuse/ActiveRecord
        def enumerator
          @enumerator ||= begin
            scope = namespace_class.where('traversal_ids[1] = ?', top_level_namespace_id)
            if cursor_data[:namespace_id]
              scope = scope.where(Namespace.arel_table[:id].gteq(cursor_data[:namespace_id]))
            end

            Enumerator.new do |enum|
              scope.each_batch(of: NAMESPACE_BATCH_SIZE) do |namespaces|
                inner_namespace_query
                  .call(namespaces)
                  .order(:id)
                  .each { |namespace| enum.yield namespace }
              end
            end
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
