# frozen_string_literal: true

module Gitlab
  module Geo
    # Geo Replicators are objects that know how to replicate a replicable resource
    #
    # A replicator is responsible for:
    # - firing events (producer)
    # - consuming events (consumer)
    #
    # Each replicator is tied to a specific replicable resource
    class Replicator
      include ::Gitlab::Utils::StrongMemoize
      include ::Gitlab::Geo::LogHelpers
      extend ::Gitlab::Geo::LogHelpers
      extend ::Gitlab::Geo::BatchCounter

      CLASS_SUFFIXES = %w(RegistryFinder RegistriesResolver).freeze

      attr_reader :model_record_id

      delegate :model, to: :class
      delegate :replication_enabled_feature_key, to: :class
      delegate :in_replicables_for_current_secondary?, to: :model_record

      class << self
        delegate :find_registries_never_attempted_sync,
                 :find_registries_needs_sync_again,
                 :fail_sync_timeouts,
                 to: :registry_class
      end

      # Declare supported event
      #
      # @example Declaring support for :update and :delete events
      #   class MyReplicator < Gitlab::Geo::Replicator
      #     event :updated
      #     event :deleted
      #   end
      #
      # @param [Symbol] event_name
      def self.event(event_name)
        @events ||= []
        @events << event_name.to_sym
      end
      private_class_method :event

      # List supported events
      #
      # @return [Array<Symbol>] with list of events
      def self.supported_events
        @events.dup
      end

      # Check if the replicator supports a specific event
      #
      # @param [Symbol] event_name
      # @return [Boolean] whether event support was registered in the replicator
      def self.event_supported?(event_name)
        @events.include?(event_name.to_sym)
      end

      # Return the canonical name of the replicable, e.g. "package_file".
      #
      # This can be used to retrieve the replicator class again
      # by using the `.for_replicable_name` method.
      #
      # @see .for_replicable_name
      # @return [String] slug that identifies this replicator
      def self.replicable_name
        self.name.demodulize.sub('Replicator', '').underscore
      end

      # Return the pluralized replicable name, e.g. "package_files". In general,
      # it is preferable to use the canonical replicable_name if possible.
      #
      # @return [String] slug that identifies this replicator, pluralized
      def self.replicable_name_plural
        self.replicable_name.pluralize
      end

      # @return [String] human-readable title of this replicator. E.g. "Package File"
      def self.replicable_title
        self.replicable_name.titleize
      end

      # @return [String] human-readable title of this replicator, pluralized. E.g. "Package Files"
      def self.replicable_title_plural
        self.replicable_name.pluralize.titleize
      end

      # @return [String] GraphQL registries field name. E.g. "packageFileRegistries"
      def self.graphql_field_name
        "#{self.replicable_name.camelize(:lower)}Registries"
      end

      # Return the registry related to the replicable resource
      #
      # @return [Class<Geo::BaseRegistry>] registry class
      def self.registry_class
        const_get("::Geo::#{replicable_name.camelize}Registry", false)
      end

      def self.registry_finder_class
        const_get("::Geo::#{replicable_name.camelize}RegistryFinder", false)
      end

      def self.graphql_registry_type
        const_get("::Types::Geo::#{replicable_name.camelize}RegistryType", false)
      end

      # Given a `replicable_name`, return the corresponding replicator class
      #
      # @param [String] replicable_name the replicable slug
      # @return [Class<Geo::Replicator>] replicator implementation
      def self.for_replicable_name(replicable_name)
        replicator_class_name = "::Geo::#{replicable_name.camelize}Replicator"

        const_get(replicator_class_name, false)
      rescue NameError
        message = "Cannot find a Geo::Replicator for #{replicable_name}"
        e = NotImplementedError.new(message)

        log_error(message, e, { replicable_name: replicable_name })

        raise e
      end

      # Given the output of a replicator's `replicable_params`, reinstantiate
      # the replicator instance
      #
      # @param [String] replicable_name of a replicator instance
      # @param [Integer] replicable_id of a replicator instance
      # @return [Geo::Replicator] replicator instance
      def self.for_replicable_params(replicable_name:, replicable_id:)
        replicator_class = for_replicable_name(replicable_name)

        replicator_class.new(model_record_id: replicable_id)
      end

      def self.primary_total_count
        batch_count(model.available_replicables, model.primary_key) do
          model.available_replicables.count
        end
      end

      def self.registry_count
        batch_count(registry_class.all, registry_class.primary_key) do
          registry_class.count
        end
      end

      def self.synced_count
        batch_count(registry_class.synced, registry_class.primary_key) do
          registry_class.synced.count
        end
      end

      def self.failed_count
        batch_count(registry_class.failed, registry_class.primary_key) do
          registry_class.failed.count
        end
      end

      def self.enabled?
        Feature.enabled?(replication_enabled_feature_key)
      end

      def self.disabled?
        !enabled?
      end

      # @example Given `Geo::PackageFileRegistryFinder`, this returns
      #   `::Geo::PackageFileReplicator`
      # @example Given `Resolver::Geo::PackageFileRegistriesResolver`, this
      #   returns `::Geo::PackageFileReplicator`
      #
      # @return [Class] a Replicator subclass
      def self.for_class_name(class_name)
        name = class_name.demodulize

        # Strip suffixes is dumb but will probably work for a while
        CLASS_SUFFIXES.each { |suffix| name.delete_suffix!(suffix) }

        const_get("::Geo::#{name}Replicator", false)
      end

      def self.replication_enabled_feature_key
        :"geo_#{replicable_name}_replication"
      end

      # Overridden by VerifiableReplicator, if it is included
      def self.verification_enabled?
        false
      end

      # :nocov:
      def self.bulk_create_delete_events_async(deleted_records)
        raise NotImplementedError
      end
      # :nocov:

      def self.bulk_create_events(events)
        ::Geo::EventLog.transaction do
          results = ::Geo::Event.insert_all!(events)

          break if results.rows.empty?

          ids = results.map { |result| { geo_event_id: result['id'], created_at: Time.current } }
          ::Geo::EventLog.insert_all!(ids)
        end

      rescue ActiveRecord::RecordInvalid, NoMethodError => e
        log_error('Geo::EventLog could not be created in bulk', e)
      end

      # @param [ActiveRecord::Base] model_record
      # @param [Integer] model_record_id
      def initialize(model_record: nil, model_record_id: nil)
        @model_record = model_record
        @model_record_id = model_record_id || model_record&.id
      end

      # Instance of the replicable model
      #
      # @return [ActiveRecord::Base, nil]
      # @raise ActiveRecord::RecordNotFound when a model with specified model_record_id can't be found
      def model_record
        if defined?(@model_record) && @model_record
          return @model_record
        end

        if model_record_id
          @model_record = model.find(model_record_id)
        end
      end

      # Publish an event with its related data
      #
      # @param [Symbol] event_name
      # @param [Hash] event_data
      def publish(event_name, **event_data)
        raise ArgumentError, "Unsupported event: '#{event_name}'" unless self.class.event_supported?(event_name)

        create_event_with(
          replicable_name: self.class.replicable_name,
          event_name: event_name,
          payload: event_data
        )
      end

      # Consume an event, using the published contextual data
      #
      # This method is called by the GeoLogCursor when reading the event from the queue
      #
      # @param [Symbol] event_name
      # @param [Hash] event_data contextual data published with the event
      def consume(event_name, **event_data)
        raise ArgumentError, "Unsupported event: '#{event_name}'" unless self.class.event_supported?(event_name)

        consume_method = "consume_event_#{event_name}".to_sym
        raise NotImplementedError, "Consume method not implemented: '#{consume_method}'" unless self.methods.include?(consume_method)

        send(consume_method, **event_data) # rubocop:disable GitlabSecurity/PublicSend
      end

      # Return the name of the replicator
      #
      # @return [String] slug that identifies this replicator
      def replicable_name
        self.class.replicable_name
      end

      # Return the registry related to the replicable resource
      #
      # @return [Class<Geo::BaseRegistry>] registry class
      def registry_class
        self.class.registry_class
      end

      # Return registry instance scoped to current model
      #
      # @return [Geo::BaseRegistry] registry instance
      def registry
        registry_class.for_model_record_id(model_record_id)
      end

      # Return exactly the data needed by `for_replicable_params` to
      # reinstantiate this Replicator elsewhere.
      #
      # @return [Hash] the replicable name and ID
      def replicable_params
        { replicable_name: replicable_name, replicable_id: model_record_id }
      end

      def handle_after_destroy
        return false unless Gitlab::Geo.primary?
        return unless self.class.enabled?

        publish(:deleted, **deleted_params)
      end

      def handle_after_update
        return false unless Gitlab::Geo.primary?
        return unless self.class.enabled?

        publish(:updated, **updated_params)

        after_verifiable_update if respond_to?(:after_verifiable_update)
      end

      def created_params
        event_params
      end

      def deleted_params
        event_params
      end

      def updated_params
        event_params
      end

      def event_params
        { model_record_id: model_record.id }
      end

      protected

      # Store an event on the database
      #
      # @example Create an event
      #   create_event_with(key: key)
      #
      # @param [Hash] **params context information that will be stored in the event table
      # @return [ApplicationRecord] event instance that was just persisted
      def create_event_with(**params)
        return unless Gitlab::Geo.primary?
        return unless Gitlab::Geo.secondary_nodes.any?

        event = ::Geo::Event.create!(**params)

        # Only works with the new geo_events at the moment because we need to
        # know which foreign key to use
        ::Geo::EventLog.create!(geo_event: event)

        event
      rescue ActiveRecord::RecordInvalid, NoMethodError => e
        log_error("::Geo::Event could not be created", e, params)
      end

      def current_node
        Gitlab::Geo.current_node
      end
    end
  end
end
