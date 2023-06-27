# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::SyncService, feature_category: :software_composition_analysis do
  describe '#execute' do
    let(:connector) { instance_double(Gitlab::PackageMetadata::Connector::Gcp, data_after: [file1, file2]) }
    let(:file1) { instance_double(Gitlab::PackageMetadata::Connector::CsvDataFile, sequence: 1675363107, chunk: 0) }
    let(:file2) { instance_double(Gitlab::PackageMetadata::Connector::CsvDataFile, sequence: 1675366673, chunk: 0) }
    let(:should_stop) { false }
    let(:stop_signal) { double('stop signal', stop?: should_stop) } # rubocop:disable RSpec/VerifiedDoubles
    let(:data_objects) { build_list(:pm_data_object, 3, purl_type: sync_config.purl_type) }

    let(:service) { described_class.new(sync_config, stop_signal) }
    let(:sync_config) { build(:pm_sync_config, version_format: 'v1') }

    subject(:execute) { service.execute }

    before do
      allow(PackageMetadata::DataObjectFabricator).to receive(:new)
        .with(data_file: file1, sync_config: sync_config).and_return(data_objects)
      allow(PackageMetadata::DataObjectFabricator).to receive(:new)
        .with(data_file: file2, sync_config: sync_config).and_return(data_objects)
      allow(Gitlab::PackageMetadata::Connector::Gcp).to receive(:new).and_return(connector)
      allow(Gitlab::PackageMetadata::Connector::Offline).to receive(:new).and_return(connector)
      allow(PackageMetadata::Ingestion::IngestionService).to receive(:execute)
      allow(PackageMetadata::Ingestion::CompressedPackage::IngestionService).to receive(:execute)
      allow(service).to receive(:sleep)
    end

    shared_examples_for 'it syncs imported data' do
      let(:checkpoint) do
        PackageMetadata::Checkpoint.first_or_initialize(purl_type: sync_config.purl_type,
          version_format: sync_config.version_format, data_type: service.data_type)
      end

      it 'calls connector with the correct checkpoint' do
        execute
        expect(connector).to have_received(:data_after).with(checkpoint)
      end

      context 'when ingesting' do
        context 'if version_format is v2' do
          before do
            sync_config.version_format = 'v2'
          end

          it 'calls compressed package ingestion service to store data' do
            execute
            expect(PackageMetadata::Ingestion::CompressedPackage::IngestionService)
              .to have_received(:execute).with(data_objects).twice
          end
        end

        context 'if version_format is v1' do
          before do
            sync_config.version_format = 'v1'
          end

          it 'calls v1 ingestion service to store data' do
            execute
            expect(PackageMetadata::Ingestion::IngestionService)
              .to have_received(:execute).with(data_objects).twice
          end
        end
      end

      it 'throttles calls to ingestion service after each ingested slice' do
        expect(service).to receive(:sleep).with(described_class::THROTTLE_RATE).twice
        service.execute
      end
    end

    context 'when checkpoint exists' do
      let(:checkpoint) do
        create(:pm_checkpoint, purl_type: sync_config.purl_type, version_format: sync_config.version_format,
          data_type: service.data_type)
      end

      it_behaves_like 'it syncs imported data'

      it 'updates the checkpoint to the last returned file' do
        expect { execute }.to change { [checkpoint.reload.sequence, checkpoint.reload.chunk] }
          .from([checkpoint.sequence, checkpoint.chunk]).to([file2.sequence, file2.chunk])
      end
    end

    context 'when checkpoint does not exist' do
      it_behaves_like 'it syncs imported data'

      it 'stores the last returned file in a new checkpoint' do
        expect { execute }.to change { PackageMetadata::Checkpoint.count }
          .from(0).to(1)

        checkpoint = PackageMetadata::Checkpoint.where(purl_type: sync_config.purl_type,
          version_format: sync_config.version_format, data_type: service.data_type)
          .first
        expect(checkpoint.sequence).to eq(file2.sequence)
        expect(checkpoint.chunk).to eq(file2.chunk)
      end
    end

    context 'when an error occurs during execution' do
      let(:seq) { 0 }
      let(:chunk) { 0 }
      let!(:checkpoint) do
        create(:pm_checkpoint, purl_type: sync_config.purl_type, sequence: seq, chunk: chunk)
      end

      before do
        allow(service).to receive(:ingest).and_raise(StandardError)
      end

      it 'does not update the checkpoint so as not to skip the errored file' do
        expect { execute }.to raise_error(StandardError)
        expect([checkpoint.reload.sequence, checkpoint.reload.chunk]).to match_array([seq, chunk])
      end
    end

    context 'when signal_stop.stop? is true' do
      let(:should_stop) { true }

      it 'terminates after checkpointing' do
        execute
        checkpoint = PackageMetadata::Checkpoint.where(purl_type: sync_config.purl_type,
          version_format: sync_config.version_format, data_type: service.data_type).first
        expect(checkpoint.sequence).to eq(file1.sequence)
        expect(checkpoint.chunk).to eq(file1.chunk)
        expect(PackageMetadata::Ingestion::IngestionService)
          .to have_received(:execute).with(data_objects).once
      end
    end

    context 'when storage_type is gcp' do
      let(:sync_config) { build(:pm_sync_config, storage_type: :gcp) }

      it_behaves_like 'it syncs imported data'
    end

    context 'when storage_type is offline' do
      let(:sync_config) { build(:pm_sync_config, storage_type: :offline) }

      it_behaves_like 'it syncs imported data'
    end

    context 'when storage_type is unknown' do
      let(:sync_config) { build(:pm_sync_config, storage_type: :foo) }

      it 'raises an error' do
        expect { execute }.to raise_error(described_class::UnknownAdapterError)
      end
    end
  end

  describe '.execute' do
    let(:observer) { instance_double(described_class) }
    let(:stop_signal) { double('stop signal', stop?: should_stop) } # rubocop:disable RSpec/VerifiedDoubles

    subject(:execute) { described_class.execute(stop_signal) }

    before do
      stub_application_setting(package_metadata_purl_types: Enums::PackageMetadata.purl_types.values)
      stub_feature_flags(compressed_package_metadata_synchronization: false)
    end

    context 'when stop_signal.stop? is false' do
      let(:should_stop) { false }

      it 'creates an instance and calls execute' do
        expect(observer).to receive(:execute).exactly(::Enums::PackageMetadata.purl_types.count).times
        ::Enums::PackageMetadata.purl_types.each do |_purl_type, _|
          expect(described_class).to receive(:new)
            .with(kind_of(PackageMetadata::SyncConfiguration), stop_signal)
            .and_return(observer)
        end
        execute
      end
    end

    context 'when stop_signal.stop? is true' do
      let(:should_stop) { true }

      it 'does not proceed' do
        expect(described_class).not_to receive(:new)
        execute
      end
    end

    context 'when none purl types enabled to sync' do
      let(:should_stop) { false }

      before do
        stub_application_setting(package_metadata_purl_types: [])
      end

      it 'does not proceed' do
        expect(described_class).not_to receive(:new)
        execute
      end
    end
  end
end
