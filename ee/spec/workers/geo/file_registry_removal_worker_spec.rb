# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::FileRegistryRemovalWorker, :geo do
  let(:replicator) { instance_double(Geo::UploadReplicator) }

  describe '#perform' do
    it 'executes the service' do
      service = instance_double(::Geo::FileRegistryRemovalService, execute: true)
      expect(::Geo::FileRegistryRemovalService)
        .to receive(:new)
        .with('upload', 123, '/path/to/a/file')
        .and_return(service)
      expect(service).to receive(:execute)

      described_class.new.perform('upload', 123, '/path/to/a/file')
    end
  end

  include_examples 'an idempotent worker' do
    let!(:upload) { create(:upload) }
    let!(:registry) { create(:geo_upload_registry, file_id: upload.id) }
    let(:job_args) { ['upload', upload.id] }

    # The service does other things, but don't test the service here.
    # This is only meant to show that the worker is idempotent.
    it 'deletes exactly one registry' do
      expect { subject }.to change(Geo::UploadRegistry, :count).by(-1)
    end
  end
end
