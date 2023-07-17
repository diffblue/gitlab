# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::AdvisoriesSyncWorker, type: :worker, feature_category: :software_composition_analysis do
  describe '#perform' do
    let(:instance) { described_class.new }
    let(:lease) { instance_double(Gitlab::ExclusiveLease) }

    subject(:perform!) { instance.perform }

    before do
      allow(instance).to receive(:try_obtain_lease).and_yield
      allow(Gitlab::ExclusiveLease).to receive(:new).and_return(lease)
    end

    shared_examples_for 'it syncs' do
      it 'calls sync service with the advisories data_type' do
        expect(PackageMetadata::SyncService).to receive(:execute)
          .with(data_type: 'advisories', lease: lease)

        perform!
      end
    end

    shared_examples_for 'it does not sync' do
      it 'does not call sync service' do
        expect(PackageMetadata::SyncService).not_to receive(:execute)

        perform!
      end
    end

    context 'when the license_scanning feature is disabled' do
      before do
        stub_licensed_features(dependency_scanning: false)
      end

      it_behaves_like 'it does not sync'
    end

    context 'when the license_scanning feature is enabled' do
      before do
        stub_licensed_features(dependency_scanning: true)
      end

      context 'and rails is not development' do
        before do
          allow(Rails.env).to receive(:development?).and_return(false)
        end

        it_behaves_like 'it syncs'
      end

      context 'and rails is development' do
        before do
          allow(Rails.env).to receive(:development?).and_return(true)
        end

        context 'and sync in dev env variable is true' do
          before do
            stub_env('PM_SYNC_IN_DEV', true)
          end

          it_behaves_like 'it syncs'
        end

        context 'and sync in dev env variable is false' do
          before do
            stub_env('PM_SYNC_IN_DEV', false)
          end

          it_behaves_like 'it does not sync'
        end
      end
    end
  end
end
