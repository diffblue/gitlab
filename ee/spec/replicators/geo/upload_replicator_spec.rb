# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::UploadReplicator do
  let(:model_record) { create(:upload, :with_file) }

  include_examples 'a blob replicator'

  describe '.bulk_create_delete_events_async' do
    let(:deleted_upload) do
      {
        model_record_id: 1,
        blob_path: 'path',
        uploader_class: 'UploaderClass'
      }
    end

    let(:deleted_uploads) { [deleted_upload] }

    it 'calls Geo::BatchEventCreateWorker and passes events array', :sidekiq_inline do
      expect { described_class.bulk_create_delete_events_async(deleted_uploads) }.to change { ::Geo::Event.count }.from(0).to(1)

      created_event = ::Geo::Event.last
      expect(created_event.replicable_name).to eq 'upload'
      expect(created_event.event_name).to eq 'deleted'
      expect(created_event.created_at).to be_present
      expect(created_event.payload).to eq(deleted_upload.stringify_keys)
    end

    it 'returns nil when empty array is passed' do
      expect(described_class.bulk_create_delete_events_async([])).to be_nil
    end
  end
end
