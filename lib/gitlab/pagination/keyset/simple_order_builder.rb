# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      # This class transforms the `order()` values from an Activerecord scope into a
      # Gitlab::Pagination::Keyset::Order instance so the query later can be  used in
      # keyset pagination.
      #
      # Return values:
      # [transformed_scope, true] # true indicates that the new scope was successfully built
      # [orginal_scope, false] # false indicates that the order values are not supported in this class
      class SimpleOrderBuilder
        def self.build(scope)
          new(scope: scope).build
        end

        def initialize(scope:)
          @scope = scope
          @order_values = scope.order_values
          @model_class = scope.model
          @arel_table = @model_class.arel_table
          @primary_key = @model_class.primary_key
        end

        def build
          return [scope.reorder!(primary_key_order(primary_key_desc)), true] if order_values.empty?
          return [scope.reorder!(keyset_order), true] if Gitlab::Pagination::Keyset::Order.keyset_aware?(scope)

          simple_order ? [scope.reorder!(simple_order), true] : [scope, false] # [scope, success]
        end

        private

        attr_reader :scope, :order_values, :model_class, :arel_table, :primary_key

        def keyset_order
          Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(scope)
        end

        def simple_order
          return unless ordered_with_arel_attributes?

          # Ordered by a primary key: 'ORDER BY id'.
          if order_values.one? && primary_key?(order_values.first)
            primary_key_order(order_values.first)
          # Ordered by one non-primary table column: 'ORDER BY created_at'.
          elsif order_values.one? && table_column?(order_values.first)
            simple_double_column_order
          # Ordered by two table columns with the last column as a tie breaker: 'ORDER BY lower(title), id'.
          elsif order_values.size == 2 && table_column?(order_values.first) && primary_key?(order_values.second)
            tie_breaker_value = order_values.second

            simple_double_column_order(tie_breaker_value)
          end
        end

        def ordered_with_arel_attributes?
          arel_attributes = order_values.map { |o| o.try(:expr) }.compact

          arel_attributes.size == order_values.size
        end

        def primary_key?(order_value)
          arel_table[primary_key].to_s == order_value.expr.to_s
        end

        def table_column?(order_value)
          return unless order_value.expr.try(:name)

          model_class.column_names.include?(order_value.expr.name.to_s)
        end

        def nullability(order_value)
          nullable = model_class.columns.find { |column| column.name == order_value.expr.name }.null

          if nullable && order_value.is_a?(Arel::Nodes::Ascending)
            :nulls_last
          elsif nullable && order_value.is_a?(Arel::Nodes::Descending)
            :nulls_first
          else
            :not_nullable
          end
        end

        def primary_key_desc
          arel_table[primary_key].desc
        end

        def primary_key_order(order_value)
          Gitlab::Pagination::Keyset::Order.build([primary_key_column(order_value)])
        end

        def simple_double_column_order(tie_breaker_value = primary_key_desc)
          Gitlab::Pagination::Keyset::Order.build([
            regular_column(order_values.first),
            primary_key_column(tie_breaker_value)
          ])
        end

        def primary_key_column(order_value)
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: model_class.primary_key,
            order_expression: order_value
          )
        end

        def regular_column(order_value)
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: order_value.expr.name,
            order_expression: order_value,
            nullable: nullability(order_value),
            distinct: false
          )
        end
      end
    end
  end
end
