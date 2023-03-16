# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::DestroyWorker, :geo, feature_category: :geo_replication do
  let(:replicator) { double(:replicator) }

  describe '#perform' do
    it 'calls replicator#replicate_destroy' do
      expect(replicator).to receive(:replicate_destroy)

      expect(Gitlab::Geo::Replicator).to receive(:for_replicable_params).with(replicable_name: 'snippet_repository', replicable_id: 1).and_return(replicator)

      described_class.new.perform('snippet_repository', 1)
    end
  end

  include_examples 'an idempotent worker' do
    let!(:upload) { create(:upload) }
    let!(:registry) { create(:geo_upload_registry, file_id: upload.id) }
    let(:job_args) { ['upload', upload.id] }

    it 'calls replicator#replicate_destroy' do
      allow(Gitlab::Geo::Replicator).to receive(:for_replicable_params).and_return(replicator)

      expect(replicator).to receive(:replicate_destroy).exactly(IdempotentWorkerHelper::WORKER_EXEC_TIMES).times

      subject
    end

    # The service does other things, but don't test the service here.
    # This is only meant to show that the worker is idempotent.
    it 'deletes exactly one registry' do
      expect { subject }.to change(Geo::UploadRegistry, :count).by(-1)
    end
  end
end
