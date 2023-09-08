# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RegistryUpdateService, :geo, feature_category: :geo_replication do
  include EE::GeoHelpers

  include_context 'with geo registries shared context'

  with_them do
    shared_context 'with a replicator context' do
      let(:registry) { create(registry_factory) } # rubocop:disable Rails/SaveBang

      let(:replicator) do
        instance_double(registry_class.replicator_class, model_record: registry.replicator.model_record)
      end

      let(:service) { described_class.new(action, registry) }

      before do
        allow(registry).to receive(:replicator).and_return(replicator)
      end
    end

    shared_examples 'a failed action performed' do
      specify do
        result = service.execute

        expect(result.message).to eq(failed_message)
        expect(result.success?).to be(false)
        expect(result.errors.size).to eq(1)
      end
    end

    describe '#execute' do
      shared_examples 'a successful individual action performed' do |success_message, method|
        specify do
          expect(registry.replicator).to receive(method)

          result = service.execute

          expect(result.message).to eq(success_message)
          expect(result.payload[:registry]).to eq(registry)
          expect(result.http_status).to eq(:ok)
        end
      end

      context 'when action is reverify' do
        let(:action) { 'reverify' }

        include_context 'with a replicator context'

        it_behaves_like(
          'a successful individual action performed',
          'Registry entry enqueued to be reverified',
          :verify_async
        )
      end

      context 'when action is resync' do
        let(:action) { 'resync' }

        include_context 'with a replicator context'

        it_behaves_like(
          'a successful individual action performed',
          'Registry entry enqueued to be resynced',
          :enqueue_sync
        )
      end

      context 'when action is not permitted' do
        let(:action) { 'unknown' }

        include_context 'with a replicator context'

        it_behaves_like 'a failed action performed' do
          let(:failed_message) { "Action 'unknown' in registry #{registry.id} entry is not supported." }
        end
      end

      context 'when an StandardError error is raised' do
        let(:action) { 'resync' }
        let(:error) { StandardError.new(registry) }

        include_context 'with a replicator context'

        before do
          allow(replicator).to receive(:enqueue_sync).and_raise(error)
        end

        it 'logs an error message with parameters' do
          expect(service).to receive(:log_error).with(
            "Could not update registry entry with action: resync",
            error.message,
            registry_id: registry.id
          )

          service.execute
        end

        it_behaves_like 'a failed action performed' do
          let(:failed_message) do
            "An error occurred while trying to update the registry: '#{error.message}'."
          end
        end
      end
    end
  end
end
