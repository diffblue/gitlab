# frozen_string_literal: true

module Gitlab
  module Ingestion
    #
    # Provides a DSL to define bulk updatable ingestion tasks.
    #
    # Tasks including this module should set a configuration value
    # and implement the template method.
    #
    # Configuration value;
    #
    #   `model`: The ActiveRecord model which the task is ingesting the data for.
    #
    # Template method;
    #
    #   `attributes`:   Returns an array of Hash objects that contain the name of the attributes and their values
    #                   as key & value pairs.
    #
    module BulkUpdatableTask
      include Gitlab::Utils::StrongMemoize

      SQL_TEMPLATE = <<~SQL
        UPDATE
          %<table_name>s
        SET
          %<set_values>s
        FROM
          (%<values>s) AS map(%<map_schema>s)
        WHERE
          %<table_name>s.%<primary_key>s = map.%<primary_key>s
      SQL

      def self.included(base)
        base.singleton_class.attr_accessor :model
      end

      def execute
        return unless attribute_names.present?

        connection.execute(update_sql)
      end

      private

      delegate :model, to: :'self.class', private: true
      delegate :table_name, :primary_key, :column_for_attribute, :type_for_attribute, :connection,
        to: :model, private: true

      def update_sql
        format(
          SQL_TEMPLATE,
          table_name: table_name,
          set_values: set_values,
          values: values,
          primary_key: primary_key,
          map_schema: map_schema
        )
      end

      def set_values
        attribute_names.map do |attribute|
          "#{attribute} = map.#{attribute}::#{sql_type_for(attribute)}"
        end.join(', ')
      end

      def sql_type_for(attribute)
        column_for_attribute(attribute).sql_type
      end

      def values
        attributes.map { |attribute_map| build_values_for(attribute_map) }
                  .then { |serialized_attributes| Arel::Nodes::ValuesList.new(serialized_attributes) }
                  .to_sql
      end

      def build_values_for(attribute_map)
        attribute_map.map { |attribute, value| type_for_attribute(attribute).serialize(value) }
      end

      def map_schema
        attribute_names.join(', ')
      end

      def attribute_names
        strong_memoize(:attribute_names) do
          attributes.first&.keys
        end
      end

      def attributes
        raise "Implement the `attributes` template method!"
      end
    end
  end
end
