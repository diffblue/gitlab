# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::FileRegistryRemovalService, :geo do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let_it_be(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#execute' do
    it 'delegates log_error to the Geo logger' do
      stub_exclusive_lease_taken("file_registry_removal_service:lfs:99")

      expect(Gitlab::Geo::Logger).to receive(:error)

      described_class.new(:lfs, 99).execute
    end

    shared_examples 'removes artifact' do
      subject(:service) { described_class.new('job_artifact', registry.artifact_id) }

      before do
        stub_exclusive_lease("file_registry_removal_service:job_artifact:#{registry.artifact_id}",
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
        end.to change(Geo::JobArtifactRegistry, :count).by(-1)
      end
    end

    shared_examples 'removes artifact registry' do
      subject(:service) { described_class.new('job_artifact', registry.artifact_id) }

      before do
        stub_exclusive_lease("file_registry_removal_service:job_artifact:#{registry.artifact_id}",
          timeout: Geo::FileRegistryRemovalService::LEASE_TIMEOUT)
      end

      it 'deletes registry entry' do
        expect do
          service.execute
        end.to change(Geo::JobArtifactRegistry, :count).by(-1)
      end
    end

    shared_examples 'removes LFS object' do
      subject(:service) { described_class.new('lfs', registry.lfs_object_id) }

      before do
        stub_exclusive_lease("file_registry_removal_service:lfs:#{registry.lfs_object_id}",
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
        end.to change(Geo::LfsObjectRegistry, :count).by(-1)
      end
    end

    shared_examples 'removes LFS object registry' do
      subject(:service) { described_class.new('lfs', registry.lfs_object_id) }

      before do
        stub_exclusive_lease("file_registry_removal_service:lfs:#{registry.lfs_object_id}",
          timeout: Geo::FileRegistryRemovalService::LEASE_TIMEOUT)
      end

      it 'deletes registry entry' do
        expect do
          service.execute
        end.to change(Geo::LfsObjectRegistry, :count).by(-1)
      end
    end

    shared_examples 'removes package file' do
      subject(:service) { described_class.new('package_file', registry.package_file_id) }

      before do
        stub_exclusive_lease("file_registry_removal_service:package_file:#{registry.package_file_id}",
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
        end.to change(Geo::PackageFileRegistry, :count).by(-1)
      end
    end

    shared_examples 'removes package file registry' do
      subject(:service) { described_class.new('package_file', registry.package_file_id) }

      before do
        stub_exclusive_lease("file_registry_removal_service:package_file:#{registry.package_file_id}",
          timeout: Geo::FileRegistryRemovalService::LEASE_TIMEOUT)
      end

      it 'deletes registry entry' do
        expect do
          service.execute
        end.to change(Geo::PackageFileRegistry, :count).by(-1)
      end
    end

    context 'with job artifact' do
      let!(:job_artifact) { create(:ci_job_artifact, :archive) }
      let!(:registry) { create(:geo_job_artifact_registry, artifact_id: job_artifact.id) }
      let!(:file_path) { job_artifact.file.path }

      it_behaves_like 'removes artifact'

      context 'migrated to object storage' do
        before do
          stub_artifacts_object_storage
          job_artifact.update_column(:file_store, JobArtifactUploader::Store::REMOTE)
        end

        it_behaves_like 'removes artifact'
      end

      context 'migrated to object storage' do
        before do
          stub_artifacts_object_storage
          job_artifact.update_column(:file_store, LfsObjectUploader::Store::REMOTE)
        end

        context 'with object storage enabled' do
          it_behaves_like 'removes artifact'
        end

        context 'with object storage disabled' do
          before do
            stub_artifacts_object_storage(enabled: false)
          end

          it_behaves_like 'removes artifact registry'
        end
      end

      context 'no job artifact record' do
        before do
          job_artifact.delete
        end

        it_behaves_like 'removes artifact' do
          subject(:service) { described_class.new('job_artifact', registry.artifact_id, file_path) }
        end
      end

      context 'with orphaned registry' do
        before do
          job_artifact.delete
        end

        it_behaves_like 'removes artifact registry' do
          subject(:service) { described_class.new('job_artifact', registry.artifact_id) }
        end
      end
    end

    context 'with package file' do
      let(:package_file) { create(:package_file_with_file) }
      let!(:registry) { create(:geo_package_file_registry, package_file: package_file) }
      let(:file_path) { Tempfile.new.path }

      before do
        allow_next_instance_of(Geo::PackageFileReplicator) do |replicator|
          allow(replicator).to receive(:blob_path).and_return(file_path)
        end
      end

      it_behaves_like 'removes package file'

      context 'no package file record' do
        before do
          package_file.delete
        end

        it_behaves_like 'removes package file' do
          subject(:service) { described_class.new('package_file', registry.package_file_id, file_path) }
        end
      end

      context 'with orphaned registry' do
        before do
          package_file.delete
        end

        it_behaves_like 'removes package file registry' do
          subject(:service) { described_class.new('package_file', registry.package_file_id) }
        end
      end
    end

    context 'with uploads' do
      let!(:upload) { create(:user, :with_avatar).avatar.upload }
      let!(:registry) { create(:geo_upload_registry, file_id: upload.id) }
      let!(:file_path) { upload.retrieve_uploader.file.path }

      subject(:service) { described_class.new('upload', registry.file_id) }

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
  end
end
