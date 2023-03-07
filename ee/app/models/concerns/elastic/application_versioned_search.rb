# frozen_string_literal: true
module Elastic
  module ApplicationVersionedSearch
    extend ActiveSupport::Concern

    FORWARDABLE_INSTANCE_METHODS = [:es_id, :es_parent, :namespace_ancestry].freeze
    FORWARDABLE_CLASS_METHODS = [:elastic_search, :es_import, :es_type, :index_name, :document_type, :mapping, :mappings, :settings, :import].freeze

    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def __elasticsearch__(&block)
      if self.class.use_separate_indices?
        @__elasticsearch_separate__ ||= ::Elastic::MultiVersionInstanceProxy.new(self, use_separate_indices: true)
      else
        @__elasticsearch__ ||= ::Elastic::MultiVersionInstanceProxy.new(self)
      end
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    # Should be overridden in the models where some records should be skipped
    def searchable?
      self.use_elasticsearch?
    end

    def use_elasticsearch?
      self.project&.use_elasticsearch?
    end

    def maintaining_elasticsearch?
      Gitlab::CurrentSettings.elasticsearch_indexing? && self.searchable?
    end

    def es_type
      self.class.es_type
    end

    included do
      delegate(*FORWARDABLE_INSTANCE_METHODS, to: :__elasticsearch__)

      class << self
        delegate(*FORWARDABLE_CLASS_METHODS, to: :__elasticsearch__)
      end

      # Add to the registry if it's a class (and not in intermediate module)
      Elasticsearch::Model::Registry.add(self) if self.is_a?(Class)

      if self < ActiveRecord::Base
        after_commit :maintain_elasticsearch_create, on: :create, if: :maintaining_elasticsearch?
        after_commit :maintain_elasticsearch_update, on: :update, if: :maintaining_elasticsearch?
        after_commit :maintain_elasticsearch_destroy, on: :destroy, if: :maintaining_elasticsearch?

        scope :preload_indexing_data, -> { __elasticsearch__.preload_indexing_data(self) }
      end
    end

    def maintain_elasticsearch_create
      ::Elastic::ProcessBookkeepingService.track!(self)
    end

    def maintain_elasticsearch_update(updated_attributes: previous_changes.keys)
      updated_attributes = updated_attributes.map(&:to_s) # Allow caller to provide symbols but keep consistent to using strings
      ::Elastic::ProcessBookkeepingService.track!(self)

      associations_to_update = associations_needing_elasticsearch_update(updated_attributes)
      if associations_to_update.present?
        ElasticAssociationIndexerWorker.perform_async(self.class.name, id, associations_to_update)
      end
    end

    def maintain_elasticsearch_destroy
      ::Elastic::ProcessBookkeepingService.track!(self)
    end

    # Override in child object if there are associations that need to be
    # updated when specific fields are updated
    def associations_needing_elasticsearch_update(updated_attributes)
      self.class.elastic_index_dependants.map do |dependant|
        association_name = dependant[:association_name]
        on_change = dependant[:on_change]

        next if updated_attributes.exclude?(on_change.to_s)

        next if dependant[:depends_on_finished_migration].present? &&
          !::Elastic::DataMigrationService.migration_has_finished?(dependant[:depends_on_finished_migration])

        association_name.to_s
      end.compact.uniq
    end

    class_methods do
      def __elasticsearch__
        if use_separate_indices?
          @__elasticsearch_separate__ ||= ::Elastic::MultiVersionClassProxy.new(self, use_separate_indices: true)
        else
          @__elasticsearch__ ||= ::Elastic::MultiVersionClassProxy.new(self)
        end
      end

      def use_separate_indices?
        false
      end

      # Mark a dependant association as needing to be updated when a specific
      # field in this object changes. For example if you want to update
      # project.issues in the index when project.visibility_level is changed
      # then you can declare that as:
      #
      # elastic_index_dependant_association :issues, on_change: :visibility_level, depends_on_finished_migration: :test_migration
      #
      def elastic_index_dependant_association(association_name, on_change:, depends_on_finished_migration: nil)
        # This class is used for non ActiveRecord models but this method is not
        # applicable for that so we raise.
        raise "elastic_index_dependant_association is not applicable as this class is not an ActiveRecord model." unless self < ActiveRecord::Base

        # Validate these are actually correct associations before sending to
        # Sidekiq to avoid errors occuring when the job is picked up.
        raise "Invalid association to index. \"#{association_name}\" is either not a collection or not an association. Hint: You must declare the has_many before declaring elastic_index_dependant_association." unless reflect_on_association(association_name)&.collection?

        elastic_index_dependants << { association_name: association_name, on_change: on_change, depends_on_finished_migration: depends_on_finished_migration }.compact
      end

      def elastic_index_dependants
        @elastic_index_dependants ||= []
      end
    end
  end
end
