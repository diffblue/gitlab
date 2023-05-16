# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RegistryUpdateService, :geo, feature_category: :geo_replication do
  include EE::GeoHelpers

  describe '#execute' do
    shared_context 'with a blob replicator context' do
      let(:registry) { create(:geo_lfs_object_registry) }

      let(:replicator) do
        instance_double(Geo::LfsObjectReplicator, model_record: registry.lfs_object)
      end

      let(:service) { described_class.new(action, 'Geo::LfsObjectRegistry', registry) }

      before do
        allow(registry).to receive(:replicator).and_return(replicator)
      end
    end

    shared_examples 'a resyncable replicable' do
      before do
        allow(registry).to receive(:replicator).and_return(replicator)
      end

      specify do
        expect(registry.replicator).to receive(:enqueue_sync)

        result = service.execute

        expect(result.message).to eq('Registry entry enqueued to be resynced')
        expect(result.payload[:registry]).to eq(registry)
        expect(result.http_status).to eq(:ok)
      end
    end

    context 'when updating a single registry' do
      context 'when action is reverify' do
        let(:action) { 'reverify' }

        include_context 'with a blob replicator context'

        it 'verifies the registry and returns a success message' do
          expect(registry.replicator).to receive(:verify_async)

          result = service.execute

          expect(result.message).to eq('Registry entry enqueued to be reverified')
          expect(result.payload[:registry]).to eq(registry)
          expect(result.http_status).to eq(:ok)
        end
      end

      context 'when action is resync' do
        let(:action) { 'resync' }

        context 'with blob replicator' do
          include_context 'with a blob replicator context'

          it_behaves_like 'a resyncable replicable'
        end

        context 'with repository replicator' do
          let_it_be_with_reload(:registry) { create(:geo_snippet_repository_registry) }

          let(:replicator) do
            instance_double(Geo::SnippetRepositoryReplicator, model_record: registry.snippet_repository)
          end

          let(:service) { described_class.new(action, 'Geo::SnippetRepositoryRegistry', registry) }

          it_behaves_like 'a resyncable replicable'
        end

        context 'with container repository replicator' do
          let_it_be_with_reload(:registry) { create(:geo_container_repository_registry) }

          let(:replicator) do
            instance_double(Geo::ContainerRepositoryReplicator, model_record: registry.container_repository)
          end

          let(:service) { described_class.new(action, 'Geo::ContainerRepositoryRegistry', registry) }

          it_behaves_like 'a resyncable replicable'
        end
      end

      context 'when action is not permitted' do
        let(:action) { 'unknown' }

        include_context 'with a blob replicator context'

        it 'returns an error message' do
          result = service.execute

          expect(result.message).to eq("Action 'unknown' in registry #{registry.id} entry is not supported.")
          expect(result.success?).to be(false)
          expect(result.errors.size).to eq(1)
        end
      end

      context 'when an StandardError error is raised' do
        let(:action) { 'resync' }
        let(:error) { StandardError.new(registry) }

        include_context 'with a blob replicator context'

        it 'logs an error and returns an error message' do
          allow(replicator).to receive(:enqueue_sync).and_raise(error)

          expect(service).to receive(:log_error).with(
            "Could not update registry entry with action: resync",
            error.message,
            registry_id: registry.id
          )

          result = service.execute

          expect(result.message).to eq(error.message)
          expect(result.success?).to be(false)
          expect(result.errors.size).to eq(1)
        end
      end
    end
  end
end
