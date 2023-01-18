# frozen_string_literal: true

module Gitlab
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
    #   `unique_by`: Optional attribute names to set unique constraint which will be used by
    #                PostgreSQL to update records on conflict. The duplicate records will be
    #                ignored by PostgreSQL if this is not provided.
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
        base.singleton_class.attr_accessor(:model, :unique_by, :uses)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Creates a proxy class to be used in UPSERT queries
        # which will also run the model layer validations except
        # the uniquness and presence of associations validations.
        def klass
          @klass ||= Class.new(model).tap do |klass|
            remove_validations(klass)

            model.const_set(:BulkInsertableProxy, klass)
          end.include(BulkInsertSafe)
        end

        private

        def remove_validations(klass)
          klass.validators.each do |validator|
            remove_validation_if_necessary(klass, validator)
          end
        end

        def remove_validation_if_necessary(klass, validator)
          return unless uniqunesss_validator?(validator) || presence_of_association_validator?(klass, validator)

          klass.skip_callback(:validate, :before, validator)
        end

        def uniqunesss_validator?(validator)
          validator.instance_of?(ActiveRecord::Validations::UniquenessValidator)
        end

        def presence_of_association_validator?(klass, validator)
          validator.instance_of?(ActiveRecord::Validations::PresenceValidator) &&
            (klass.reflections.keys & validator.attributes.map(&:to_s)).any?
        end
      end

      def execute
        return_data

        after_ingest if uses
      end

      private

      delegate :unique_by, :model, :klass, :uses, :cast_values, to: :'self.class', private: true

      def return_data
        strong_memoize(:return_data) do
          if insert_objects.present?
            unique_by.present? ? bulk_upsert : bulk_insert
          else
            []
          end
        end
      end

      def bulk_insert
        klass.bulk_insert!(insert_objects, skip_duplicates: true, returns: uses)
      end

      def bulk_upsert
        klass.bulk_upsert!(insert_objects, unique_by: unique_by, returns: uses) { |attr| slice_attributes(attr) }
      end

      def after_ingest
        raise "Implement the `after_ingest` template method!"
      end

      def attributes
        raise "Implement the `attributes` template method!"
      end

      def insert_objects
        @insert_objects ||= insert_attributes.map { |attributes| klass.new(attributes) }
      end

      def insert_attributes
        @insert_attributes ||= unique_attributes.map { |values| values.merge(timestamps) }
      end

      def unique_attributes
        return attributes unless unique_by.present?

        attributes.uniq { |values| values.with_indifferent_access.slice(*unique_by) }
      end

      # `BulkInsertSafe` module is trying to update all the attributes
      # of a record which overrides the columns with NULL values if the
      # attribute is not provided. For this reason, we need to slice the
      # attributes with this callback.
      def slice_attributes(item_attributes)
        item_attributes.slice!(*attribute_names)
      end

      def attribute_names
        @attribute_names ||= insert_attributes.first.keys.map(&:to_s)
      end

      def timestamps
        @timestamps ||= Time.zone.now.then { |time| { created_at: time, updated_at: time } }
      end
    end
  end
end
