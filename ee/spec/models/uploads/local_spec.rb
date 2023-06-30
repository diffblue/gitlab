# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploads::Local, :geo do
  include ::EE::GeoHelpers

  let(:data_store) { described_class.new }

  before do
    stub_uploads_object_storage(FileUploader)
  end

  context 'on a primary when secondary nodes exist' do
    let(:project) { create(:project) }
    let(:relation) { project.uploads }

    before do
      allow(::Geo::EventStore).to receive(:can_create_event?).and_return(true)
    end

    describe '#keys' do
      let(:upload) { create(:upload, uploader: FileUploader, model: project) }
      let!(:uploads) { [upload] }

      it 'returns keys' do
        keys = data_store.keys(relation)

        expected_hash = {
          absolute_path: upload.absolute_path,
          blob_path: upload.retrieve_uploader.relative_path,
          model_record_id: upload.id,
          uploader_class: "FileUploader"
        }

        expect(keys.size).to eq 1
        expect(keys.first).to include(expected_hash)
      end
    end

    describe '#delete_keys_async' do
      it 'performs calls to DeleteStoredFilesWorker and Geo::UploadReplicator.bulk_create_delete_events_async' do
        keys_to_delete = [{
          absolute_path: 'absolute_path',
          blob_path: 'relative_path',
          model_record_id: 1,
          uploader_class: "FileUploader"
        }]

        expect(::DeleteStoredFilesWorker).to receive(:perform_async).with(described_class, ['absolute_path'])
        expect(::Geo::UploadReplicator).to receive(:bulk_create_delete_events_async).with(keys_to_delete)

        data_store.delete_keys_async(keys_to_delete)
      end
    end
  end
end
