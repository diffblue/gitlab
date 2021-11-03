# frozen_string_literal: true

module EE
  module GeoHelpers
    def stub_current_geo_node(node)
      allow(::Gitlab::Geo).to receive(:current_node).and_return(node)

      # GeoNode.current? returns true only when the node is passed
      # otherwise it returns false
      allow(GeoNode).to receive(:current?).and_return(false)
      allow(GeoNode).to receive(:current?).with(node).and_return(true)
    end

    def stub_current_node_name(name)
      allow(GeoNode).to receive(:current_node_name).and_return(name)
    end

    def stub_primary_node
      allow(::Gitlab::Geo).to receive(:primary?).and_return(true)
      allow(::Gitlab::Geo).to receive(:secondary?).and_return(false)
    end

    def stub_secondary_node
      allow(::Gitlab::Geo).to receive(:primary?).and_return(false)
      allow(::Gitlab::Geo).to receive(:secondary?).and_return(true)
    end

    def create_project_on_shard(shard_name)
      project = create(:project)

      # skipping validation which requires the shard name to exist in Gitlab.config.repositories.storages.keys
      project.update_column(:repository_storage, shard_name)

      project
    end

    def registry_factory_name(registry_class)
      registry_class.underscore.tr('/', '_').to_sym
    end

    def with_no_geo_database_configured(&block)
      allow(::Gitlab::Geo).to receive(:geo_database_configured?).and_return(false)

      yield

      # We need to unstub here or the DatabaseCleaner will have issues since it
      # will appear as though the tracking DB were not available
      allow(::Gitlab::Geo).to receive(:geo_database_configured?).and_call_original
    end

    def stub_dummy_replicator_class
      stub_const('Geo::DummyReplicator', Class.new(::Gitlab::Geo::Replicator))

      ::Geo::DummyReplicator.class_eval do
        event :test
        event :another_test

        def self.model
          ::DummyModel
        end

        def handle_after_create_commit
          true
        end

        def handle_after_checksum_succeeded
          true
        end

        protected

        def consume_event_test(user:, other:)
          true
        end
      end
    end

    def stub_dummy_model_class
      stub_const('DummyModel', Class.new(ApplicationRecord))

      DummyModel.class_eval do
        include ::Gitlab::Geo::ReplicableModel
        include ::Gitlab::Geo::VerificationState

        with_replicator Geo::DummyReplicator

        def self.replicables_for_current_secondary(primary_key_in)
          self.primary_key_in(primary_key_in)
        end
      end

      DummyModel.reset_column_information
    end

    # Example:
    #
    # before(:all) do
    #   create_dummy_model_table
    # end
    #
    # after(:all) do
    #   drop_dummy_model_table
    # end
    def create_dummy_model_table
      ActiveRecord::Schema.define do
        create_table :dummy_models, force: true do |t|
          t.binary :verification_checksum
          t.integer :verification_state
          t.datetime_with_timezone :verification_started_at
          t.datetime_with_timezone :verified_at
          t.datetime_with_timezone :verification_retry_at
          t.integer :verification_retry_count
          t.text :verification_failure
        end
      end
    end

    def drop_dummy_model_table
      ActiveRecord::Schema.define do
        drop_table :dummy_models, force: true
      end
    end
  end
end
