# frozen_string_literal: true

module Security
  module Ingestion
    #
    # Provides a DSL to define bulk insertable ingestion tasks.
    #
    # Tasks including this module should set some configuration value(s)
    # and implement the template method(s).
    #
    # Configuration values;
    #
    #   `model`:     The ActiveRecord model which the task is ingesting the data for.
    #   `unique_by`: Optional value to set unique constraint which will be used by
    #                PostgreSQL to update records on conflict. The task raises an exception
    #                in case of a conflict if this is not set.
    #   `uses`:      Optional value to set return columns of the insert query.
    #                The method named `after_ingest` will be called if this value is set.
    #
    # Template methods;
    #
    #   `attributes`:   Returns an array of Hash objects that contain the name of the attributes and their values
    #                   as key & value pairs.
    #   `after_ingest`: If the task uses the return value(s) of insert query, this method will
    #                   be called. The return data of the insert query can be accessible by the `return_data` method.
    #
    module BulkInsertableTask
      include Gitlab::Utils::StrongMemoize

      def self.included(base)
        base.singleton_class.attr_accessor :model, :unique_by, :uses
      end

      def execute
        result_set

        after_ingest if uses
      end

      private

      delegate :unique_by, :model, :uses, :cast_values, to: :'self.class', private: true

      def return_data
        @return_data ||= result_set&.cast_values(model.attribute_types).to_a
      end

      def result_set
        strong_memoize(:result_set) do
          if insert_attributes.present?
            ActiveRecord::InsertAll.new(model, insert_attributes, on_duplicate: on_duplicate, returning: uses, unique_by: unique_by).execute
          end
        end
      end

      def after_ingest
        raise "Implement the `after_ingest` template method!"
      end

      def attributes
        raise "Implement the `attributes` template method!"
      end

      def insert_attributes
        @insert_attributes ||= attributes.map { |values| values.merge(timestamps) }
      end

      def timestamps
        @timestamps ||= Time.zone.now.then { |time| { created_at: time, updated_at: time } }
      end

      def on_duplicate
        unique_by.present? ? :update : :skip
      end
    end
  end
end
