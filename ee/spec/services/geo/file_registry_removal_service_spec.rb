# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::FileRegistryRemovalService, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let_it_be(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
  end

  def expect_to_log_a_message_with(object_db_id, message, level: :error)
    allow(Gitlab::Geo::Logger)
        .to receive(level)
        .with(any_args)

    Array(message).each do |message|
      expect(Gitlab::Geo::Logger)
        .to receive(level)
        .with(
          hash_including(
            message: message,
            object_db_id: object_db_id,
            object_type: :upload
          )
        )
    end
  end

  describe '#execute' do
    let_it_be(:project) { create(:project) }

    context 'when upload registry record exists' do
      context 'with file on local storage' do
        context 'when file exists on disk' do
          let!(:upload) { create(:upload, :issuable_upload, :with_file, model: project) }
          let!(:registry) { create(:geo_upload_registry, file_id: upload.id) }

          subject(:service) { described_class.new('upload', upload.id) }

          before do
            stub_exclusive_lease("file_registry_removal_service:upload:#{upload.id}",
              timeout: described_class::LEASE_TIMEOUT)
          end

          it 'removes the file' do
            expect { service.execute }.to change { File.exist?(upload.absolute_path) }.from(true).to(false)
          end

          it 'removes upload registry record' do
            expect { service.execute }.to change(Geo::UploadRegistry, :count).by(-1)
          end

          context 'when something went wrong removing the file' do
            before do
              allow(File).to receive(:unlink).with(anything).and_raise(SystemCallError, 'Something went wrong')
            end

            it 'logs an error message' do
              expect_to_log_a_message_with(upload.id, 'Could not remove file')

              expect { service.execute }.to raise_error(SystemCallError, /Something went wrong/)
            end

            it 'does not remove the upload registry record' do
              expect { service.execute }
                .to change(Geo::UploadRegistry, :count).by(0)
                .and(raise_error(SystemCallError, /Something went wrong/))
            end
          end
        end

        context 'when file does not exist on disk' do
          let!(:upload) { create(:upload, :issuable_upload, model: project) }
          let!(:registry) { create(:geo_upload_registry, file_id: upload.id) }

          subject(:service) { described_class.new('upload', upload.id) }

          before do
            stub_exclusive_lease("file_registry_removal_service:upload:#{upload.id}",
              timeout: described_class::LEASE_TIMEOUT)
          end

          it 'does not remove the file' do
            expect(File).not_to receive(:unlink).with(upload.absolute_path)

            service.execute
          end

          it 'removes upload registry record' do
            expect { service.execute }.to change(Geo::UploadRegistry, :count).by(-1)
          end
        end
      end

      context 'with file on remote storage' do
        let!(:upload) { create(:upload, :issuable_upload, :object_storage, model: project) }
        let!(:registry) { create(:geo_upload_registry, file_id: upload.id) }

        subject(:service) { described_class.new('upload', upload.id) }

        before do
          stub_exclusive_lease("file_registry_removal_service:upload:#{upload.id}",
            timeout: described_class::LEASE_TIMEOUT)
        end

        context 'when object storage is enabled' do
          before do
            stub_uploads_object_storage(FileUploader)
          end

          context 'when file exists on object storage' do
            context 'when Gitlab managed replication is enabled' do
              it 'removes the file' do
                remote_file = double(destroy: true) # rubocop:disable RSpec/VerifiedDoubles
                file_uploader = upload.retrieve_uploader
                blob_path = FileUploader.absolute_path(file_uploader)
                blob_path = blob_path.delete_prefix("#{file_uploader.root}/")

                expect_next_instances_of(Fog::Storage::AWS::Files, 2) do |files|
                  expect(files).to receive(:head).with(blob_path).once.and_return(remote_file)
                end

                expect_to_log_a_message_with(upload.id, "Removing #{blob_path} from uploads", level: :info)
                expect(remote_file).to receive(:destroy).once

                service.execute
              end

              it 'removes upload registry record' do
                expect { service.execute }.to change(Geo::UploadRegistry, :count).by(-1)
              end
            end

            context 'when Gitlab managed replication is disabled' do
              before do
                allow(secondary).to receive(:sync_object_storage).and_return(false)
              end

              it 'does not remove the file' do
                expect(Fog::Storage).not_to receive(:new)

                expect_to_log_a_message_with(
                  upload.id,
                  'Skipping file deletion as this secondary node is not allowed to replicate content on Object Storage',
                  level: :info
                )

                service.execute
              end

              it 'removes upload registry record' do
                expect { service.execute }.to change(Geo::UploadRegistry, :count).by(-1)
              end
            end
          end

          context 'when file does not exist on object storage' do
            context 'when GitLab managed replication is enabled' do
              it 'does not remove the file' do
                file_uploader = upload.retrieve_uploader
                blob_path = FileUploader.absolute_path(file_uploader)
                blob_path = blob_path.delete_prefix("#{file_uploader.root}/")

                expect_next_instance_of(Fog::Storage::AWS::Files) do |files|
                  expect(files).to receive(:head).with(blob_path).once.and_return(nil)
                end

                expect_to_log_a_message_with(
                  upload.id, "Can't find #{blob_path} in object storage path uploads"
                )

                service.execute
              end

              it 'removes upload registry record' do
                expect { service.execute }.to change(Geo::UploadRegistry, :count).by(-1)
              end
            end

            context 'when Gitlab managed replication is disabled' do
              before do
                allow(secondary).to receive(:sync_object_storage).and_return(false)
              end

              it 'skips file removal' do
                expect(Fog::Storage).not_to receive(:new)

                expect_to_log_a_message_with(
                  upload.id,
                  'Skipping file deletion as this secondary node is not allowed to replicate content on Object Storage',
                  level: :info
                )

                service.execute
              end

              it 'removes upload registry record' do
                expect { service.execute }.to change(Geo::UploadRegistry, :count).by(-1)
              end
            end
          end
        end

        context 'when object storage is disabled' do
          before do
            stub_uploads_object_storage(FileUploader, enabled: false)
          end

          context 'when Gitlab managed replication is enabled' do
            it 'does not remove the file' do
              expect(Fog::Storage).not_to receive(:new)

              expect_to_log_a_message_with(
                upload.id, 'Unable to unlink file because file path is unknown. A file may be orphaned.'
              )

              service.execute
            end

            it 'removes upload registry record' do
              expect { service.execute }.to change(Geo::UploadRegistry, :count).by(-1)
            end
          end

          context 'when Gitlab managed replication is disabled' do
            before do
              allow(secondary).to receive(:sync_object_storage).and_return(false)
            end

            it 'does not remove the file' do
              expect(Fog::Storage).not_to receive(:new)

              expect_to_log_a_message_with(
                upload.id, 'Unable to unlink file because file path is unknown. A file may be orphaned.'
              )

              service.execute
            end

            it 'removes upload registry record' do
              expect { service.execute }.to change(Geo::UploadRegistry, :count).by(-1)
            end
          end
        end
      end
    end

    context 'when upload registry record does not exist' do
      context 'with file on local storage' do
        context 'when file exists on disk' do
          let!(:upload) { create(:upload, :issuable_upload, :with_file, model: project) }

          subject(:service) { described_class.new('upload', upload.id) }

          before do
            stub_exclusive_lease("file_registry_removal_service:upload:#{upload.id}",
              timeout: described_class::LEASE_TIMEOUT)
          end

          it 'removes the file' do
            expect { service.execute }.to change { File.exist?(upload.absolute_path) }.from(true).to(false)
          end

          it 'does not remove an upload registry record' do
            expect { service.execute }.not_to change(Geo::UploadRegistry, :count)
          end

          context 'when something went wrong removing the file' do
            before do
              allow(File).to receive(:unlink).with(anything).and_raise(SystemCallError, 'Something went wrong')
            end

            it 'logs an error message' do
              expect_to_log_a_message_with(upload.id, 'Could not remove file')

              expect { service.execute }.to raise_error(SystemCallError, /Something went wrong/)
            end

            it 'does not remove an upload registry record' do
              expect { service.execute }
                .to change(Geo::UploadRegistry, :count).by(0)
                .and(raise_error(SystemCallError, /Something went wrong/))
            end
          end
        end

        context 'when file does not exist on disk' do
          let!(:upload) { create(:upload, :issuable_upload, model: project) }

          subject(:service) { described_class.new('upload', upload.id) }

          before do
            stub_exclusive_lease("file_registry_removal_service:upload:#{upload.id}",
              timeout: described_class::LEASE_TIMEOUT)
          end

          it 'does not remove the file' do
            expect(File).not_to receive(:unlink).with(upload.absolute_path)

            service.execute
          end

          it 'does not remove an upload registry record' do
            expect { service.execute }.not_to change(Geo::UploadRegistry, :count)
          end
        end
      end

      context 'with file on remote storage' do
        let!(:upload) { create(:upload, :issuable_upload, :object_storage, model: project) }

        subject(:service) { described_class.new('upload', upload.id) }

        before do
          stub_exclusive_lease("file_registry_removal_service:upload:#{upload.id}",
            timeout: described_class::LEASE_TIMEOUT)
        end

        context 'when object storage is enabled' do
          before do
            stub_uploads_object_storage(FileUploader)
          end

          context 'when file exists on object storage' do
            context 'when GitLab managed replication is enabled' do
              it 'removes the file' do
                remote_file = double(destroy: true) # rubocop:disable RSpec/VerifiedDoubles
                file_uploader = upload.retrieve_uploader
                blob_path = FileUploader.absolute_path(file_uploader)
                blob_path = blob_path.delete_prefix("#{file_uploader.root}/")

                expect_next_instances_of(Fog::Storage::AWS::Files, 2) do |files|
                  expect(files).to receive(:head).with(blob_path).once.and_return(remote_file)
                end

                expect_to_log_a_message_with(upload.id, "Removing #{blob_path} from uploads", level: :info)
                expect(remote_file).to receive(:destroy).once

                service.execute
              end

              it 'does not remove an upload registry record' do
                expect { service.execute }.not_to change(Geo::UploadRegistry, :count)
              end
            end

            context 'when Gitlab managed replication is disabled' do
              before do
                allow(secondary).to receive(:sync_object_storage).and_return(false)
              end

              it 'skips file removal' do
                expect(Fog::Storage).not_to receive(:new)

                expect_to_log_a_message_with(
                  upload.id,
                  'Skipping file deletion as this secondary node is not allowed to replicate content on Object Storage',
                  level: :info
                )

                service.execute
              end

              it 'does not remove an upload registry record' do
                expect { service.execute }.not_to change(Geo::UploadRegistry, :count)
              end
            end
          end

          context 'when file does not exist on object storage' do
            context 'when GitLab managed replicaiton is enabled' do
              it 'does not remove the file' do
                file_uploader = upload.retrieve_uploader
                blob_path = FileUploader.absolute_path(file_uploader)
                blob_path = blob_path.delete_prefix("#{file_uploader.root}/")

                expect_next_instance_of(Fog::Storage::AWS::Files) do |files|
                  expect(files).to receive(:head).with(blob_path).once.and_return(nil)
                end

                expect_to_log_a_message_with(upload.id, "Can't find #{blob_path} in object storage path uploads")

                service.execute
              end

              it 'does not remove an upload registry record' do
                expect { service.execute }.not_to change(Geo::UploadRegistry, :count)
              end
            end

            context 'when Gitlab managed replication is disabled' do
              before do
                allow(secondary).to receive(:sync_object_storage).and_return(false)
              end

              it 'skips file removal' do
                expect(Fog::Storage).not_to receive(:new)

                expect_to_log_a_message_with(
                  upload.id,
                  'Skipping file deletion as this secondary node is not allowed to replicate content on Object Storage',
                  level: :info
                )

                service.execute
              end

              it 'does not remove an upload registry record' do
                expect { service.execute }.not_to change(Geo::UploadRegistry, :count)
              end
            end
          end
        end

        context 'when object storage is disabled' do
          before do
            stub_uploads_object_storage(FileUploader, enabled: false)
          end

          context 'when GitLab managed replication is enabled' do
            it 'does not remove the file' do
              expect(Fog::Storage).not_to receive(:new)

              expect_to_log_a_message_with(
                upload.id, 'Unable to unlink file because file path is unknown. A file may be orphaned.'
              )

              service.execute
            end

            it 'does not remove an upload registry record' do
              expect { service.execute }.not_to change(Geo::UploadRegistry, :count)
            end
          end

          context 'when GitLab managed replication is disabled' do
            before do
              allow(secondary).to receive(:sync_object_storage).and_return(false)
            end

            it 'does not remove the file' do
              expect(Fog::Storage).not_to receive(:new)

              expect_to_log_a_message_with(
                upload.id, 'Unable to unlink file because file path is unknown. A file may be orphaned.'
              )

              service.execute
            end

            it 'does not remove an upload registry record' do
              expect { service.execute }.not_to change(Geo::UploadRegistry, :count)
            end
          end
        end
      end
    end

    context 'when upload record does not exist' do
      context 'with file on local storage' do
        context 'when the file_path is passed' do
          context 'when file exists on disk' do
            let!(:upload) { create(:upload, :issuable_upload, :with_file, model: project) }
            let!(:registry) { create(:geo_upload_registry, file_id: upload.id) }

            subject(:service) { described_class.new('upload', upload.id, upload.absolute_path) }

            before do
              stub_exclusive_lease("file_registry_removal_service:upload:#{upload.id}",
                timeout: described_class::LEASE_TIMEOUT)

              upload.delete
            end

            it 'removes the file' do
              expect { service.execute }.to change { File.exist?(upload.absolute_path) }.from(true).to(false)
            end

            it 'removes upload registry record' do
              expect { service.execute }.to change(Geo::UploadRegistry, :count).by(-1)
            end

            context 'when something went wrong removing the file' do
              before do
                allow(File).to receive(:unlink).with(anything).and_raise(SystemCallError, 'Something went wrong')
              end

              it 'logs an error message' do
                expect_to_log_a_message_with(upload.id, 'Could not remove file')

                expect { service.execute }.to raise_error(SystemCallError, /Something went wrong/)
              end

              it 'does not remove the upload registry record' do
                expect { service.execute }
                  .to change(Geo::UploadRegistry, :count).by(0)
                  .and(raise_error(SystemCallError, /Something went wrong/))
              end
            end
          end

          context 'when file does not exist on disk' do
            let!(:upload) { create(:upload, :issuable_upload, model: project) }
            let!(:registry) { create(:geo_upload_registry, file_id: upload.id) }

            subject(:service) { described_class.new('upload', upload.id) }

            before do
              stub_exclusive_lease("file_registry_removal_service:upload:#{upload.id}",
                timeout: described_class::LEASE_TIMEOUT)

              upload.delete
            end

            it 'does not remove the file' do
              expect(File).not_to receive(:unlink).with(upload.absolute_path)

              service.execute
            end

            it 'removes upload registry record' do
              expect { service.execute }.to change(Geo::UploadRegistry, :count).by(-1)
            end
          end
        end

        context 'when the file_path is not passed' do
          context 'when file exists on disk' do
            let!(:upload) { create(:upload, :issuable_upload, :with_file, model: project) }
            let!(:registry) { create(:geo_upload_registry, file_id: upload.id) }
            let!(:object_db_id) { upload.id }

            subject(:service) { described_class.new('upload', object_db_id) }

            before do
              stub_exclusive_lease("file_registry_removal_service:upload:#{object_db_id}",
                timeout: described_class::LEASE_TIMEOUT)

              upload.delete
            end

            it 'logs an error message' do
              expect_to_log_a_message_with(
                upload.id,
                [
                  'Could not build uploader',
                  'Unable to unlink file because file path is unknown. A file may be orphaned.'
                ]
              )

              subject.execute
            end

            it 'removes upload registry record' do
              expect { service.execute }.to change(Geo::UploadRegistry, :count).by(-1)
            end
          end

          context 'when file does not exist on disk' do
            let!(:upload) { create(:upload, :issuable_upload, model: project) }
            let!(:registry) { create(:geo_upload_registry, file_id: upload.id) }
            let!(:object_db_id) { upload.id }

            subject(:service) { described_class.new('upload', object_db_id) }

            before do
              stub_exclusive_lease("file_registry_removal_service:upload:#{object_db_id}",
                timeout: described_class::LEASE_TIMEOUT)

              upload.delete
            end

            it 'logs an error message' do
              expect_to_log_a_message_with(
                upload.id,
                [
                  'Could not build uploader',
                  'Unable to unlink file because file path is unknown. A file may be orphaned.'
                ]
              )

              subject.execute
            end

            it 'removes upload registry record' do
              expect { service.execute }.to change(Geo::UploadRegistry, :count).by(-1)
            end
          end
        end
      end

      context 'with file on remote storage' do
        context 'when the file_path is passed' do
          let!(:upload) { create(:upload, :issuable_upload, :object_storage, model: project) }
          let!(:registry) { create(:geo_upload_registry, file_id: upload.id) }

          before do
            stub_exclusive_lease("file_registry_removal_service:upload:#{upload.id}",
              timeout: described_class::LEASE_TIMEOUT)
          end

          context 'when object storage is enabled' do
            before do
              stub_uploads_object_storage(FileUploader)
            end

            context 'when GitLab managed replication is enabled' do
              it 'logs an error message' do
                file_uploader = upload.retrieve_uploader
                blob_path = FileUploader.absolute_path(file_uploader)
                blob_path = blob_path.delete_prefix("#{file_uploader.root}/")
                upload.delete

                expect_to_log_a_message_with(
                  upload.id, 'Unable to unlink file from filesystem, or object storage. A file may be orphaned.'
                )

                described_class.new('upload', upload.id, blob_path).execute
              end

              it 'removes upload registry record' do
                file_uploader = upload.retrieve_uploader
                blob_path = FileUploader.absolute_path(file_uploader)
                blob_path = blob_path.delete_prefix("#{file_uploader.root}/")
                upload.delete

                expect { described_class.new('upload', upload.id, blob_path).execute }
                  .to change(Geo::UploadRegistry, :count).by(-1)
              end
            end

            context 'when Gitlab managed replication is disabled' do
              before do
                allow(secondary).to receive(:sync_object_storage).and_return(false)
              end

              it 'logs an error message' do
                file_uploader = upload.retrieve_uploader
                blob_path = FileUploader.absolute_path(file_uploader)
                blob_path = blob_path.delete_prefix("#{file_uploader.root}/")
                upload.delete

                expect(Fog::Storage).not_to receive(:new)

                expect_to_log_a_message_with(
                  upload.id, 'Unable to unlink file from filesystem, or object storage. A file may be orphaned.'
                )

                described_class.new('upload', upload.id, blob_path).execute
              end

              it 'removes upload registry record' do
                file_uploader = upload.retrieve_uploader
                blob_path = FileUploader.absolute_path(file_uploader)
                blob_path = blob_path.delete_prefix("#{file_uploader.root}/")
                upload.delete

                expect { described_class.new('upload', upload.id, blob_path).execute }
                  .to change(Geo::UploadRegistry, :count).by(-1)
              end
            end
          end

          context 'when object storage is disabled' do
            context 'when Gitlab managed replication is enabled' do
              it 'logs an error message' do
                stub_uploads_object_storage(FileUploader)

                file_uploader = upload.retrieve_uploader
                blob_path = FileUploader.absolute_path(file_uploader)
                blob_path = blob_path.delete_prefix("#{file_uploader.root}/")
                upload.delete

                stub_uploads_object_storage(FileUploader, enabled: false)

                expect_to_log_a_message_with(
                  upload.id, 'Unable to unlink file from filesystem, or object storage. A file may be orphaned.'
                )

                described_class.new('upload', upload.id, blob_path).execute
              end

              it 'removes upload registry record' do
                stub_uploads_object_storage(FileUploader)

                file_uploader = upload.retrieve_uploader
                blob_path = FileUploader.absolute_path(file_uploader)
                blob_path = blob_path.delete_prefix("#{file_uploader.root}/")
                upload.delete

                stub_uploads_object_storage(FileUploader, enabled: false)

                expect { described_class.new('upload', upload.id, blob_path).execute }
                  .to change(Geo::UploadRegistry, :count).by(-1)
              end
            end

            context 'when Gitlab managed replication is disabled' do
              before do
                allow(secondary).to receive(:sync_object_storage).and_return(false)
              end

              it 'logs an error message' do
                stub_uploads_object_storage(FileUploader)

                file_uploader = upload.retrieve_uploader
                blob_path = FileUploader.absolute_path(file_uploader)
                blob_path = blob_path.delete_prefix("#{file_uploader.root}/")
                upload.delete

                stub_uploads_object_storage(FileUploader, enabled: false)

                expect_to_log_a_message_with(
                  upload.id, 'Unable to unlink file from filesystem, or object storage. A file may be orphaned.'
                )

                described_class.new('upload', upload.id, blob_path).execute
              end

              it 'removes upload registry record' do
                stub_uploads_object_storage(FileUploader)

                file_uploader = upload.retrieve_uploader
                blob_path = FileUploader.absolute_path(file_uploader)
                blob_path = blob_path.delete_prefix("#{file_uploader.root}/")
                upload.delete

                stub_uploads_object_storage(FileUploader, enabled: false)

                expect { described_class.new('upload', upload.id, blob_path).execute }
                  .to change(Geo::UploadRegistry, :count).by(-1)
              end
            end
          end
        end

        context 'when the file_path is not passed' do
          let!(:upload) { create(:upload, :issuable_upload, :object_storage, model: project) }
          let!(:registry) { create(:geo_upload_registry, file_id: upload.id) }

          context 'when object storage is enabled' do
            subject(:service) { described_class.new('upload', upload.id) }

            before do
              stub_uploads_object_storage(FileUploader)

              upload.delete
            end

            context 'when GitLab managed replication is enabled' do
              it 'logs an error message' do
                expect_to_log_a_message_with(
                  upload.id, 'Unable to unlink file because file path is unknown. A file may be orphaned.'
                )

                service.execute
              end

              it 'removes upload registry record' do
                expect { service.execute }.to change(Geo::UploadRegistry, :count).by(-1)
              end
            end

            context 'when Gitlab managed replication is disabled' do
              before do
                allow(secondary).to receive(:sync_object_storage).and_return(false)
              end

              it 'logs an error message' do
                expect_to_log_a_message_with(
                  upload.id, 'Unable to unlink file because file path is unknown. A file may be orphaned.'
                )

                service.execute
              end

              it 'removes upload registry record' do
                expect { service.execute }.to change(Geo::UploadRegistry, :count).by(-1)
              end
            end
          end

          context 'when object storage is disabled' do
            subject(:service) { described_class.new('upload', upload.id) }

            before do
              stub_uploads_object_storage(FileUploader, enabled: false)

              upload.delete
            end

            context 'when GitLab managed replication is enabled' do
              it 'logs an error message' do
                expect_to_log_a_message_with(
                  upload.id, 'Unable to unlink file because file path is unknown. A file may be orphaned.'
                )

                service.execute
              end

              it 'removes upload registry record' do
                expect { service.execute }.to change(Geo::UploadRegistry, :count).by(-1)
              end
            end

            context 'when GitLab managed replication is disabled' do
              before do
                allow(secondary).to receive(:sync_object_storage).and_return(false)
              end

              it 'logs an error message' do
                expect_to_log_a_message_with(
                  upload.id, 'Unable to unlink file because file path is unknown. A file may be orphaned.'
                )

                service.execute
              end

              it 'removes upload registry record' do
                expect { service.execute }.to change(Geo::UploadRegistry, :count).by(-1)
              end
            end
          end
        end
      end
    end

    context 'with an unrecognized replicable type' do
      context 'with file on local storage' do
        let!(:upload) { create(:upload, :issuable_upload, :with_file, model: project) }
        let!(:registry) { create(:geo_upload_registry, file_id: upload.id) }

        subject(:service) { described_class.new('foo', upload.id) }

        before do
          stub_exclusive_lease("file_registry_removal_service:foo:#{upload.id}",
            timeout: described_class::LEASE_TIMEOUT)
        end

        it 'raises an error' do
          expect { service.execute }.to raise_error(NoMethodError, "undefined method `registry' for nil:NilClass")
        end
      end

      context 'with file on remote storage' do
        context 'when the file_path is passed' do
          let!(:upload) { create(:upload, :issuable_upload, :object_storage, model: project) }
          let!(:registry) { create(:geo_upload_registry, file_id: upload.id) }

          subject(:service) { described_class.new('foo', upload.id) }

          before do
            stub_exclusive_lease("file_registry_removal_service:foo:#{upload.id}",
              timeout: described_class::LEASE_TIMEOUT)
          end

          context 'when object storage is enabled' do
            before do
              stub_uploads_object_storage(FileUploader)
            end

            context 'when GitLab managed replication is enabled' do
              it 'raises an error' do
                expect { service.execute }.to raise_error(NoMethodError, "undefined method `registry' for nil:NilClass")
              end
            end

            context 'when GitLab managed replication is disabled' do
              it 'raises an error' do
                allow(secondary).to receive(:sync_object_storage).and_return(false)

                expect { service.execute }.to raise_error(NoMethodError, "undefined method `registry' for nil:NilClass")
              end
            end
          end

          context 'when object storage is disabled' do
            before do
              stub_uploads_object_storage(FileUploader, enabled: false)
            end

            context 'when GitLab managed replication is enabled' do
              it 'raises an error' do
                expect { service.execute }.to raise_error(NoMethodError, "undefined method `registry' for nil:NilClass")
              end
            end

            context 'when GitLab managed replication is disabled' do
              before do
                allow(secondary).to receive(:sync_object_storage).and_return(false)
              end

              it 'raises an error' do
                expect { service.execute }.to raise_error(NoMethodError, "undefined method `registry' for nil:NilClass")
              end
            end
          end
        end
      end
    end
  end
end
