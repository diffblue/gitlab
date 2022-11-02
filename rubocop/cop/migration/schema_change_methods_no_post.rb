# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks that no background batched migration helpers are called by regular migrations.
      class SchemaChangeMethodsNoPost < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = "This method may not be used in post migrations."
        PATH_TIMESTAMP_MATCHER = /\d{14}/.freeze

        FORBIDDEN_METHODS = %w[
          add_column
          create_table
          add_concurrent_foreign_key
        ].freeze

        SYMBOLIZED_MATCHER = FORBIDDEN_METHODS.map { |w| ":#{w}" }.join(' | ')

        def_node_matcher :on_forbidden_method, <<~PATTERN
          (send nil? {#{SYMBOLIZED_MATCHER}} ...)
        PATTERN

        def on_send(node)
          return unless time_enforced?(node)

          on_forbidden_method(node) do
            add_offense(node, message: MSG)
          end
        end
      end
    end
  end
end
