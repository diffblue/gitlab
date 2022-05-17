# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::FileRegistryRemovalService, :geo do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let_it_be(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
  end

  shared_examples 'removes upload' do
    subject(:service) { described_class.new('upload', registry.file_id, file_path) }

    before do
      stub_exclusive_lease("file_registry_removal_service:upload:#{registry.file_id}",
        timeout: Geo::FileRegistryRemovalService::LEASE_TIMEOUT)
    end

    it 'file from disk' do
      expect do
        service.execute
      end.to change { File.exist?(file_path) }.from(true).to(false)
    end

    it 'deletes registry entry' do
      expect do
        service.execute
      end.to change(Geo::UploadRegistry, :count).by(-1)
    end
  end

  shared_examples 'removes upload registry' do
    subject(:service) { described_class.new('upload', registry.file_id, file_path) }

    before do
      stub_exclusive_lease("file_registry_removal_service:upload:#{registry.file_id}",
        timeout: Geo::FileRegistryRemovalService::LEASE_TIMEOUT)
    end

    it 'deletes registry entry' do
      expect do
        service.execute
      end.to change(Geo::UploadRegistry, :count).by(-1)
    end
  end

  describe '#execute' do
    let!(:upload) { create(:upload, :with_file) }
    let!(:registry) { create(:geo_upload_registry, file_id: upload.id) }
    let!(:file_path) { upload.retrieve_uploader.file.path }

    it 'delegates log_error to the Geo logger' do
      stub_exclusive_lease_taken("file_registry_removal_service:lfs:99")

      expect(Gitlab::Geo::Logger).to receive(:error)

      described_class.new(:lfs, 99).execute
    end

    it_behaves_like 'removes upload'

    context 'migrated to object storage' do
      before do
        upload.update_column(:store, ObjectStorage::Store::REMOTE)
      end

      context 'with object storage enabled' do
        before do
          stub_uploads_object_storage(AvatarUploader)
        end

        it_behaves_like 'removes upload'
      end

      context 'with object storage disabled' do
        before do
          stub_uploads_object_storage(AvatarUploader, enabled: false)
        end

        it_behaves_like 'removes upload registry'
      end
    end

    context 'no upload record' do
      before do
        upload.delete
      end

      it_behaves_like 'removes upload' do
        subject(:service) { described_class.new('upload', registry.file_id, file_path) }
      end

      it_behaves_like 'removes upload registry'
    end
  end
end
