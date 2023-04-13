# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::SyncService, feature_category: :software_composition_analysis do
  describe '#execute' do
    let(:version_format) { 'v1' }
    let(:purl_type) { :composer }
    let(:connector) { instance_double(Gitlab::PackageMetadata::Connector::Gcp, data_after: [file1, file2]) }
    let(:file1) { data_objects }
    let(:file2) { data_objects }
    let(:should_stop) { false }
    let(:stop_signal) { double('stop signal', stop?: should_stop) } # rubocop:disable RSpec/VerifiedDoubles

    let(:data_objects) do
      [
        Hashie::Mash.new(name: 'foo', version: 'v1', license: 'MIT', purl_type: purl_type),
        Hashie::Mash.new(name: 'bar', version: 'v2', license: 'Apache', purl_type: purl_type),
        Hashie::Mash.new(name: 'baz', version: 'v100', license: 'unknown', purl_type: purl_type)
      ]
    end

    let(:service) { described_class.new(connector, version_format, purl_type, stop_signal) }

    subject(:execute) { service.execute }

    before do
      allow(PackageMetadata::Ingestion::IngestionService).to receive(:execute)
      allow(file1).to receive(:sequence).and_return(1675363107)
      allow(file1).to receive(:chunk).and_return(0)
      allow(file2).to receive(:sequence).and_return(1675366673)
      allow(file2).to receive(:chunk).and_return(0)
      allow(service).to receive(:sleep)
    end

    shared_examples_for 'it syncs imported data' do
      let(:checkpoint) do
        PackageMetadata::Checkpoint.first_or_initialize(purl_type: purl_type)
      end

      it 'calls connector with the correct checkpoint' do
        execute
        expect(connector).to have_received(:data_after).with(checkpoint)
      end

      it 'calls ingestion service to store the data' do
        execute
        expect(PackageMetadata::Ingestion::IngestionService).to have_received(:execute).with(data_objects).twice
      end

      it 'throttles calls to ingestion service after each ingested slice' do
        expect(service).to receive(:sleep).with(described_class::THROTTLE_RATE).twice
        service.execute
      end
    end

    context 'when checkpoint exists' do
      let(:checkpoint) { create(:pm_checkpoint, purl_type: purl_type) }

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

        checkpoint = PackageMetadata::Checkpoint.where(purl_type: purl_type).first
        expect(checkpoint.sequence).to eq(file2.sequence)
        expect(checkpoint.chunk).to eq(file2.chunk)
      end
    end

    context 'when an error occurs during execution' do
      let(:seq) { 0 }
      let(:chunk) { 0 }
      let!(:checkpoint) do
        create(:pm_checkpoint, purl_type: purl_type, sequence: seq, chunk: chunk)
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
        checkpoint = PackageMetadata::Checkpoint.where(purl_type: purl_type).first
        expect(checkpoint.sequence).to eq(file1.sequence)
        expect(checkpoint.chunk).to eq(file1.chunk)
        expect(PackageMetadata::Ingestion::IngestionService).to have_received(:execute).with(data_objects).once
      end
    end
  end

  describe '.execute' do
    let(:observer) { instance_double(described_class) }
    let(:stop_signal) { double('stop signal', stop?: should_stop) } # rubocop:disable RSpec/VerifiedDoubles

    subject(:execute) { described_class.execute(stop_signal) }

    before do
      stub_application_setting(package_metadata_purl_types: Enums::PackageMetadata.purl_types.values)
    end

    context 'when stop_signal.stop? is false' do
      let(:should_stop) { false }

      it 'creates an instance and calls execute' do
        expect(observer).to receive(:execute).exactly(::Enums::PackageMetadata.purl_types.count).times
        ::Enums::PackageMetadata.purl_types.each do |purl_type, _|
          expect(described_class).to receive(:new).with(kind_of(Gitlab::PackageMetadata::Connector::Gcp), 'v1',
            purl_type, stop_signal).and_return(observer)
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

  describe '.connector_for' do
    let(:configuration) { PackageMetadata::SyncConfiguration.new(storage_type, 'a_base_uri', 'v1', 'npm') }

    subject(:connector) { described_class.connector_for(configuration) }

    context 'with a supported storage type' do
      context 'and it is gcp' do
        let(:storage_type) { :gcp }

        it { is_expected.to be_a_kind_of(Gitlab::PackageMetadata::Connector::Gcp) }
      end

      context 'and it is offline' do
        let(:storage_type) { :offline }

        it { is_expected.to be_a_kind_of(Gitlab::PackageMetadata::Connector::Offline) }
      end
    end

    context 'with an unknown storage type' do
      let(:storage_type) { :an_unknown_service }

      it 'raises an error' do
        expect { connector }.to raise_error(PackageMetadata::SyncService::UnknownAdapterError)
      end
    end
  end
end
