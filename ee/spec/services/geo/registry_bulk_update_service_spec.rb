# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RegistryBulkUpdateService, :geo, feature_category: :geo_replication do
  include EE::GeoHelpers

  let(:service) { described_class.new(action, registry_class.name) }

  include_context 'with geo registries shared context'

  with_them do
    shared_examples 'a failed action performed' do
      specify do
        result = service.execute

        expect(result.message).to eq(failed_message)
        expect(result.success?).to be(false)
        expect(result.errors.size).to eq(1)
      end
    end

    describe '#execute' do
      shared_examples 'a successful bulk action performed' do |success_message, worker_class|
        specify do
          expect(worker_class).to receive(:perform_with_capacity).with(registry_class.name)

          result = service.execute

          expect(result.message).to eq(success_message)
          expect(result.payload[:registry_class]).to eq(registry_class.name)
          expect(result.http_status).to eq(:ok)
        end
      end

      context 'when action is resync_all' do
        let(:action) { 'resync_all' }

        it_behaves_like(
          'a successful bulk action performed',
          'Registries enqueued to be resynced',
          Geo::BulkMarkPendingBatchWorker
        )
      end

      context 'when action is reverify_all' do
        let(:action) { 'reverify_all' }

        it_behaves_like(
          'a successful bulk action performed',
          'Registries enqueued to be reverified',
          Geo::BulkMarkVerificationPendingBatchWorker
        )
      end

      context 'when action is not permitted' do
        let(:action) { 'unknown' }

        it_behaves_like 'a failed action performed' do
          let(:failed_message) { "Action 'unknown' in registries is not supported." }
        end
      end

      context 'when an StandardError error is raised' do
        let(:action) { 'resync_all' }
        let(:error) { StandardError.new(registry_class.name) }

        before do
          allow(Geo::BulkMarkPendingBatchWorker).to receive(:perform_with_capacity)
                                                      .with(registry_class.name)
                                                      .and_raise(error)
        end

        it 'logs an error message with parameters' do
          expect(service).to receive(:log_error).with(
            "Could not update registries with action: resync_all",
            error.message,
            registry_class: registry_class.name
          )

          service.execute
        end

        it_behaves_like 'a failed action performed' do
          let(:failed_message) do
            "An error occurred while trying to update the registries: '#{error.message}'."
          end
        end
      end
    end
  end
end
