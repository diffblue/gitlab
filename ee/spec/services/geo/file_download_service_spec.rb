# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::FileDownloadService do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)

    stub_feature_flags(geo_upload_replication: false)
  end

  describe '#downloader' do
    Gitlab::Geo::Replication::USER_UPLOADS_OBJECT_TYPES.each do |object_type|
      it "returns a FileDownloader given object_type is #{object_type}" do
        subject = described_class.new(object_type, 1)

        expect(subject.downloader).to be_a(Gitlab::Geo::Replication::FileDownloader)
      end
    end

    it "returns a JobArtifactDownloader given object_type is job_artifact" do
      subject = described_class.new('job_artifact', 1)

      expect(subject.downloader).to be_a(Gitlab::Geo::Replication::JobArtifactDownloader)
    end
  end

  context 'retry time' do
    before do
      stub_transfer_result(bytes_downloaded: 0, success: false)
    end

    shared_examples_for 'a service that sets next retry time capped at some value' do
      it 'ensures the next retry time is capped properly' do
        download_service.execute

        expect(registry_entry.reload).to have_attributes(
          retry_at: be_within(100.seconds).of(1.hour.from_now),
          retry_count: 32
        )
      end
    end

    context 'with job_artifacts' do
      let!(:registry_entry) do
        create(:geo_job_artifact_registry, success: false, retry_count: 31, artifact_id: file.id)
      end

      let(:file) { create(:ci_job_artifact) }
      let(:download_service) { described_class.new('job_artifact', file.id) }

      it_behaves_like 'a service that sets next retry time capped at some value'
    end

    context 'with uploads' do
      let!(:registry_entry) do
        create(:geo_upload_legacy_registry, :avatar, success: false, file_id: file.id, retry_count: 31)
      end

      let(:file) { create(:upload) }
      let(:download_service) { described_class.new('avatar', file.id) }

      it_behaves_like 'a service that sets next retry time capped at some value'
    end
  end

  shared_examples_for 'a service that handles orphaned uploads' do |file_type|
    let(:download_service) { described_class.new(file_type, file.id) }
    let(:registry) { Geo::UploadRegistry }

    before do
      stub_exclusive_lease("file_download_service:#{file_type}:#{file.id}",
        timeout: Geo::FileDownloadService::LEASE_TIMEOUT)

      file.update_column(:model_id, 22222) # Not-existing record
    end

    it 'marks upload as successful and missing_on_primary' do
      expect(Gitlab::Geo::Logger).to receive(:info).with(hash_including(:message,
                                                                        :download_time_s,
                                                                        download_success: true,
                                                                        bytes_downloaded: 0,
                                                                        primary_missing_file: true)).and_call_original

      expect { download_service.execute }.to change { registry.synced.missing_on_primary.count }.by(1)
    end
  end

  shared_examples_for 'a service that downloads the file and registers the sync result' do |file_type|
    let(:download_service) { described_class.new(file_type, file.id) }

    let(:registry) do
      case file_type
      when 'job_artifact'
        Geo::JobArtifactRegistry
      else
        Geo::UploadRegistry
      end
    end

    subject(:execute!) { download_service.execute }

    before do
      stub_exclusive_lease("file_download_service:#{file_type}:#{file.id}",
        timeout: Geo::FileDownloadService::LEASE_TIMEOUT)
    end

    context 'for a new file' do
      context 'when the downloader fails before attempting a transfer' do
        it 'logs that the download failed before attempting a transfer' do
          result = double(:result, success: false, bytes_downloaded: 0, primary_missing_file: false, failed_before_transfer: true, reason: 'Something went wrong')
          downloader = double(:downloader, execute: result)
          allow(download_service).to receive(:downloader).and_return(downloader)

          expect(Gitlab::Geo::Logger)
            .to receive(:info)
            .with(hash_including(:message, :download_time_s, download_success: false, reason: 'Something went wrong', bytes_downloaded: 0, failed_before_transfer: true))
            .and_call_original

          execute!
        end
      end

      context 'when the downloader attempts a transfer' do
        context 'when the file is successfully downloaded' do
          before do
            stub_transfer_result(bytes_downloaded: 100, success: true)
          end

          it 'registers the file' do
            expect { execute! }.to change { registry.count }.by(1)
          end

          it 'marks the file as synced' do
            expect { execute! }.to change { registry.synced.count }.by(1)
          end

          it 'does not mark the file as missing on the primary' do
            execute!

            expect(registry.last.missing_on_primary).to be_falsey
          end

          it 'logs the result' do
            expect(Gitlab::Geo::Logger).to receive(:info).with(hash_including(:message, :download_time_s, download_success: true, bytes_downloaded: 100)).and_call_original

            execute!
          end

          it 'resets the retry fields' do
            execute!

            expect(registry.last.reload.retry_count).to eq(0)
            expect(registry.last.retry_at).to be_nil
          end
        end

        context 'when the file fails to download' do
          context 'when the file is missing on the primary' do
            before do
              stub_transfer_result(bytes_downloaded: 100, success: true, primary_missing_file: true)
            end

            it 'registers the file' do
              expect { execute! }.to change { registry.count }.by(1)
            end

            it 'marks the file as synced' do
              expect { execute! }.to change { registry.synced.count }.by(1)
            end

            it 'marks the file as missing on the primary' do
              execute!

              expect(registry.last.missing_on_primary).to be_truthy
            end

            it 'logs the result' do
              expect(Gitlab::Geo::Logger).to receive(:info).with(hash_including(:message, :download_time_s, download_success: true, bytes_downloaded: 100, primary_missing_file: true)).and_call_original

              execute!
            end

            it 'sets a retry date and increments the retry count' do
              freeze_time do
                execute!

                expect(registry.last.reload.retry_count).to eq(1)
                expect(registry.last.retry_at > Time.current).to be_truthy
              end
            end
          end

          context 'when the file is not missing on the primary' do
            before do
              stub_transfer_result(bytes_downloaded: 0, success: false)
            end

            it 'registers the file' do
              expect { execute! }.to change { registry.count }.by(1)
            end

            it 'marks the file as failed to sync' do
              expect { execute! }.to change { registry.failed.count }.by(1)
            end

            it 'does not mark the file as missing on the primary' do
              execute!

              expect(registry.last.missing_on_primary).to be_falsey
            end

            it 'sets a retry date and increments the retry count' do
              freeze_time do
                execute!

                expect(registry.last.reload.retry_count).to eq(1)
                expect(registry.last.retry_at > Time.current).to be_truthy
              end
            end
          end
        end
      end
    end

    context 'for a registered file that failed to sync' do
      let!(:registry_entry) do
        case file_type
        when 'job_artifact'
          create(:geo_job_artifact_registry, success: false, artifact_id: file.id, retry_count: 3, retry_at: 1.hour.ago)
        else
          create(:geo_upload_legacy_registry, file_type.to_sym, success: false, file_id: file.id, retry_count: 3, retry_at: 1.hour.ago)
        end
      end

      context 'when the file is successfully downloaded' do
        before do
          stub_transfer_result(bytes_downloaded: 100, success: true)
        end

        it 'does not register a new file' do
          expect { execute! }.not_to change { registry.count }
        end

        it 'marks the file as synced' do
          expect { execute! }.to change { registry.synced.count }.by(1)
        end

        it 'resets the retry fields' do
          execute!

          expect(registry_entry.reload.retry_count).to eq(0)
          expect(registry_entry.retry_at).to be_nil
        end

        context 'when the file was marked as missing on the primary' do
          before do
            registry_entry.update_column(:missing_on_primary, true)
          end

          it 'marks the file as no longer missing on the primary' do
            execute!

            expect(registry_entry.reload.missing_on_primary).to be_falsey
          end
        end

        context 'when the file was not marked as missing on the primary' do
          it 'does not mark the file as missing on the primary' do
            execute!

            expect(registry_entry.reload.missing_on_primary).to be_falsey
          end
        end
      end

      context 'when the file fails to download' do
        context 'when the file is missing on the primary' do
          before do
            stub_transfer_result(bytes_downloaded: 100, success: true, primary_missing_file: true)
          end

          it 'does not register a new file' do
            expect { execute! }.not_to change { registry.count }
          end

          it 'marks the file as synced' do
            expect { execute! }.to change { registry.synced.count }.by(1)
          end

          it 'marks the file as missing on the primary' do
            execute!

            expect(registry_entry.reload.missing_on_primary).to be_truthy
          end

          it 'logs the result' do
            expect(Gitlab::Geo::Logger).to receive(:info).with(hash_including(:message, :download_time_s, download_success: true, bytes_downloaded: 100, primary_missing_file: true)).and_call_original

            execute!
          end

          it 'sets a retry date and increments the retry count' do
            freeze_time do
              execute!

              expect(registry_entry.reload.retry_count).to eq(4)
              expect(registry_entry.retry_at > Time.current).to be_truthy
            end
          end

          it 'sets a retry date with a maximum of about 4 hours' do
            registry_entry.update!(retry_count: 100, retry_at: 1.minute.ago)

            freeze_time do
              execute!

              expect(registry_entry.reload.retry_at).to be_within(3.minutes).of(4.hours.from_now)
            end
          end
        end

        context 'when the file is not missing on the primary' do
          before do
            stub_transfer_result(bytes_downloaded: 0, success: false)
          end

          it 'does not register a new file' do
            expect { execute! }.not_to change { registry.count }
          end

          it 'does not change the success flag' do
            expect { execute! }.not_to change { registry.failed.count }
          end

          it 'does not mark the file as missing on the primary' do
            execute!

            expect(registry_entry.reload.missing_on_primary).to be_falsey
          end

          it 'sets a retry date and increments the retry count' do
            freeze_time do
              execute!

              expect(registry_entry.reload.retry_count).to eq(4)
              expect(registry_entry.retry_at > Time.current).to be_truthy
            end
          end

          it 'sets a retry date with a maximum of about 1 hour' do
            registry_entry.update!(retry_count: 100, retry_at: 1.minute.ago)

            freeze_time do
              execute!

              expect(registry_entry.reload.retry_at).to be_within(3.minutes).of(1.hour.from_now)
            end
          end
        end
      end
    end
  end

  describe '#execute' do
    context 'user avatar' do
      let(:file) { create(:upload, model: build(:user)) }

      it_behaves_like "a service that downloads the file and registers the sync result", 'avatar'
      it_behaves_like 'a service that handles orphaned uploads', 'avatar'
    end

    context 'group avatar' do
      let(:file) { create(:upload, model: build(:group)) }

      it_behaves_like "a service that downloads the file and registers the sync result", 'avatar'
      it_behaves_like 'a service that handles orphaned uploads', 'avatar'
    end

    context 'project avatar' do
      let(:file) { create(:upload, model: build(:project)) }

      it_behaves_like "a service that downloads the file and registers the sync result", 'avatar'
      it_behaves_like 'a service that handles orphaned uploads', 'avatar'
    end

    context 'with an attachment' do
      let(:file) { create(:upload, :attachment_upload) }

      it_behaves_like "a service that downloads the file and registers the sync result", 'attachment'
      it_behaves_like 'a service that handles orphaned uploads', 'attachment'
    end

    context 'with a favicon' do
      let(:file) { create(:upload, :favicon_upload) }

      it_behaves_like "a service that downloads the file and registers the sync result", 'favicon'
      it_behaves_like 'a service that handles orphaned uploads', 'favicon'
    end

    context 'with a snippet' do
      let(:file) { create(:upload, :personal_snippet_upload) }

      it_behaves_like "a service that downloads the file and registers the sync result", 'personal_file'
      it_behaves_like 'a service that handles orphaned uploads', 'personal_file'
    end

    context 'with file upload' do
      let(:file) { create(:upload, :issuable_upload) }

      it_behaves_like "a service that downloads the file and registers the sync result", 'file'
      it_behaves_like 'a service that handles orphaned uploads', 'file'
    end

    context 'with namespace file upload' do
      let(:file) { create(:upload, :namespace_upload) }

      it_behaves_like "a service that downloads the file and registers the sync result", 'namespace_file'
      it_behaves_like 'a service that handles orphaned uploads', 'namespace_file'
    end

    context 'with an incident metrics upload' do
      let(:file) { create(:upload, :issue_metric_image) }

      it_behaves_like 'a service that downloads the file and registers the sync result', 'issuable_metric_image'
      it_behaves_like 'a service that handles orphaned uploads', 'issuable_metric_image'
    end

    context 'job artifacts' do
      it_behaves_like "a service that downloads the file and registers the sync result", 'job_artifact' do
        let(:file) { create(:ci_job_artifact) }
      end
    end

    context 'Import/Export' do
      let(:file) { create(:upload, model: build(:import_export_upload)) }

      it_behaves_like "a service that downloads the file and registers the sync result", 'import_export'
      it_behaves_like 'a service that handles orphaned uploads', 'import_export'
    end

    context 'with bulk imports export upload' do
      let(:file) { create(:upload, model: build(:bulk_import_export_upload)) }

      it_behaves_like 'a service that downloads the file and registers the sync result', :'bulk_imports/export'
      it_behaves_like 'a service that handles orphaned uploads', :'bulk_imports/export'
    end

    context 'bad object type' do
      it 'raises an error' do
        expect { described_class.new(:bad, 1).execute }.to raise_error(NotImplementedError)
      end
    end
  end

  def stub_transfer_result(bytes_downloaded:, success: false, primary_missing_file: false)
    result = double(:transfer_result,
                    bytes_downloaded: bytes_downloaded,
                    success: success,
                    primary_missing_file: primary_missing_file)
    instance = double("(instance of Gitlab::Geo::Replication::Transfer)", download_from_primary: result)
    allow(Gitlab::Geo::Replication::BaseTransfer).to receive(:new).and_return(instance)
  end
end
