# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::FileDownloadService do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
    stub_feature_flags(geo_job_artifact_replication: false)
  end

  describe '#downloader' do
    it "returns a JobArtifactDownloader given object_type is job_artifact" do
      subject = described_class.new('job_artifact', 1)

      expect(subject.downloader).to be_a(Gitlab::Geo::Replication::JobArtifactDownloader)
    end
  end

  context 'retry time' do
    before do
      stub_transfer_result(bytes_downloaded: 0, success: false)
    end

    context 'with job_artifacts' do
      let!(:geo_job_artifact_registry) do
        create(:geo_job_artifact_registry_legacy, success: false, retry_count: 31, artifact_id: file.id)
      end

      let(:file) { create(:ci_job_artifact) }
      let(:download_service) { described_class.new('job_artifact', file.id) }

      it 'ensures the next retry time is capped properly' do
        download_service.execute

        expect(geo_job_artifact_registry.reload).to have_attributes(
          retry_at: be_within(100.seconds).of(1.hour.from_now),
          retry_count: 32
        )
      end
    end
  end

  describe '#execute' do
    context 'job artifacts' do
      let(:file) { create(:ci_job_artifact) }
      let(:download_service) { described_class.new('job_artifact', file.id) }

      let(:registry) do
        Geo::JobArtifactRegistry
      end

      subject(:execute!) { download_service.execute }

      before do
        stub_exclusive_lease("file_download_service:job_artifact:#{file.id}",
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
        let!(:geo_job_artifact_registry) do
          create(:geo_job_artifact_registry_legacy, success: false, artifact_id: file.id, retry_count: 3, retry_at: 1.hour.ago)
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

            expect(geo_job_artifact_registry.reload.retry_count).to eq(0)
            expect(geo_job_artifact_registry.retry_at).to be_nil
          end

          context 'when the file was marked as missing on the primary' do
            before do
              geo_job_artifact_registry.update_column(:missing_on_primary, true)
            end

            it 'marks the file as no longer missing on the primary' do
              execute!

              expect(geo_job_artifact_registry.reload.missing_on_primary).to be_falsey
            end
          end

          context 'when the file was not marked as missing on the primary' do
            it 'does not mark the file as missing on the primary' do
              execute!

              expect(geo_job_artifact_registry.reload.missing_on_primary).to be_falsey
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

              expect(geo_job_artifact_registry.reload.missing_on_primary).to be_truthy
            end

            it 'logs the result' do
              expect(Gitlab::Geo::Logger).to receive(:info).with(hash_including(:message, :download_time_s, download_success: true, bytes_downloaded: 100, primary_missing_file: true)).and_call_original

              execute!
            end

            it 'sets a retry date and increments the retry count' do
              freeze_time do
                execute!

                expect(geo_job_artifact_registry.reload.retry_count).to eq(4)
                expect(geo_job_artifact_registry.retry_at > Time.current).to be_truthy
              end
            end

            it 'sets a retry date with a maximum of about 4 hours' do
              geo_job_artifact_registry.update!(retry_count: 100, retry_at: 1.minute.ago)

              freeze_time do
                execute!

                expect(geo_job_artifact_registry.reload.retry_at).to be_within(3.minutes).of(4.hours.from_now)
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

              expect(geo_job_artifact_registry.reload.missing_on_primary).to be_falsey
            end

            it 'sets a retry date and increments the retry count' do
              freeze_time do
                execute!

                expect(geo_job_artifact_registry.reload.retry_count).to eq(4)
                expect(geo_job_artifact_registry.retry_at > Time.current).to be_truthy
              end
            end

            it 'sets a retry date with a maximum of about 1 hour' do
              geo_job_artifact_registry.update!(retry_count: 100, retry_at: 1.minute.ago)

              freeze_time do
                execute!

                expect(geo_job_artifact_registry.reload.retry_at).to be_within(3.minutes).of(1.hour.from_now)
              end
            end
          end
        end
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
