# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::Replication::BlobDownloader, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }

  let(:model_record) { create(:package_file, :npm) }
  let(:replicator) { model_record.replicator }

  subject { described_class.new(replicator: replicator) }

  describe '#execute' do
    before do
      stub_current_geo_node(secondary)
    end

    context 'precondition failures' do
      context 'not a Geo secondary' do
        it 'returns failure' do
          stub_current_geo_node(primary)

          result = subject.execute

          expect(result.success).to be_falsey
        end
      end

      context 'no Geo primary exists' do
        it 'returns failure' do
          primary.update!(primary: false)

          result = subject.execute

          expect(result.success).to be_falsey
        end
      end

      context 'when the file is locally stored' do
        context 'when the file destination is already taken by a directory' do
          it 'returns failure' do
            path = replicator.carrierwave_uploader.path
            expect(File).to receive(:directory?).with(path).and_return(true)

            result = subject.execute

            expect(result.success).to be_falsey
          end
        end

        xit 'ensures the file destination directory exists' # Not worth testing here as-is. Extract the functionality first.
      end

      context 'when the file is on Object Storage' do
        let!(:secondary_object_storage) { create(:geo_node, sync_object_storage: sync_object_storage) }

        before do
          stub_package_file_object_storage(enabled: true, direct_upload: true)
          stub_current_geo_node(secondary_object_storage)
        end

        let!(:model_record) { create(:package_file, :npm, :object_storage) }

        subject { described_class.new(replicator: model_record.replicator) }

        context 'with object storage sync enabled' do
          let(:sync_object_storage) { true }

          context 'when the primary proxies remote storage' do
            it 'returns success' do
              content = replicator.carrierwave_uploader.file.read
              size = content.bytesize
              stub_request(:get, subject.resource_url)
                .to_return(status: 200, body: content)

              result = subject.execute

              expect_blob_downloader_result(result, success: true, bytes_downloaded: size, primary_missing_file: false)
            end
          end

          context 'when the primary redirects to remote storage' do
            let(:geo_internal_headers) { { 'Authorization' => 'Gl-Geo: abc123' } }
            let(:content) { replicator.carrierwave_uploader.file.read }
            let(:size) { content.bytesize }
            let(:remote_url) { replicator.carrierwave_uploader.url }

            before do
              # Set up to ensure that our redirect follow implementation does
              # not pass through all headers.
              allow_next_instance_of(Gitlab::Geo::TransferRequest) do |request|
                allow(request).to receive(:headers).and_return(geo_internal_headers)
              end

              stub_request(:get, subject.resource_url)
                .to_return(status: 302, headers: { 'Location' => remote_url })

              # This stub is intended to cause this test to fail when all
              # headers are passed through (per HTTP.rb `follow` behavior) to
              # the redirect location.
              #
              # Some S3-compatible storages respond with 400 Bad Request when
              # there are unexpected headers. See
              # https://gitlab.com/gitlab-org/gitlab/-/issues/201995
              stub_request(:get, remote_url)
                .to_return(status: 400, body: content, headers: geo_internal_headers)

              stub_request(:get, remote_url)
                .to_return(status: 200, body: content)
            end

            it 'returns success', :aggregate_failures do
              result = subject.execute

              expect_blob_downloader_result(result, success: true, bytes_downloaded: size, primary_missing_file: false)

              # Expect that the redirect is followed
              expect(WebMock).to have_requested(:get, remote_url)
            end
          end

          context 'with object storage disabled' do
            before do
              stub_package_file_object_storage(enabled: false)
            end

            it 'returns failure' do
              result = subject.execute

              expect(result.success).to be_falsey
            end
          end
        end

        context 'with object storage sync disabled' do
          let(:sync_object_storage) { false }

          it 'returns failure' do
            result = subject.execute

            expect(result.success).to be_falsey
          end
        end
      end
    end

    context 'when an error occurs while getting a Tempfile' do
      it 'returns failure' do
        subject

        expect(Tempfile).to receive(:new).and_raise('boom')

        result = subject.execute

        expect(result.success).to be_falsey
        expect(result.extra_details).to have_key(:error)
      end
    end

    context 'when the HTTP response is unsuccessful' do
      context 'when the HTTP response indicates a missing file on the primary' do
        it 'returns a failed result indicating primary_missing_file' do
          stub_request(:get, subject.resource_url)
            .to_return(status: 404,
                       headers: { content_type: 'application/json' },
                       body: { geo_code: Gitlab::Geo::Replication::FILE_NOT_FOUND_GEO_CODE }.to_json)

          result = subject.execute

          expect_blob_downloader_result(result, success: false, bytes_downloaded: 0, primary_missing_file: true, reason: 'The file is missing on the Geo primary site')
        end
      end

      context 'when the HTTP response does not indicate a missing file on the primary' do
        it 'returns a failed result' do
          stub_request(:get, subject.resource_url)
            .to_return(status: 404,
                       headers: { content_type: 'application/json' },
                       body: 'Not found')

          result = subject.execute

          expect_blob_downloader_result(result, success: false, bytes_downloaded: 0, primary_missing_file: false, reason: 'Non-success HTTP response status code 404')
        end
      end
    end

    context 'when the HTTP response is successful' do
      it 'returns success' do
        path = replicator.carrierwave_uploader.path
        content = replicator.carrierwave_uploader.file.read
        size = content.bytesize
        stub_request(:get, subject.resource_url).to_return(status: 200, body: content)

        result = subject.execute
        stat = File.stat(path)

        expect_blob_downloader_result(result, success: true, bytes_downloaded: size, primary_missing_file: false)
        expect(stat.size).to eq(size)
        expect(stat.mode & 0777).to eq(0666 - File.umask)
        expect(File.binread(path)).to eq(content)
      end

      context 'when the checksum of the downloaded file does not match' do
        it 'returns a failed result' do
          allow(replicator).to receive(:primary_checksum).and_return('something')
          bad_content = 'corrupted!!!'
          stub_request(:get, subject.resource_url)
            .to_return(status: 200, body: bad_content)

          result = subject.execute

          expect_blob_downloader_result(result, success: false, bytes_downloaded: bad_content.bytesize, primary_missing_file: false)
        end
      end

      context 'when the primary has not stored a checksum for the file' do
        it 'returns a successful result' do
          expect(replicator).to receive(:primary_checksum).and_return(nil)
          content = 'foo'
          stub_request(:get, subject.resource_url)
            .to_return(status: 200, body: content)

          result = subject.execute

          expect_blob_downloader_result(result, success: true, bytes_downloaded: content.bytesize, primary_missing_file: false)
        end
      end
    end
  end

  def expect_blob_downloader_result(result, success:, bytes_downloaded:, primary_missing_file:, reason: nil)
    expect(result.success).to eq(success)
    expect(result.bytes_downloaded).to eq(bytes_downloaded)
    expect(result.primary_missing_file).to eq(primary_missing_file)

    if reason
      expect(result.reason).to eq(reason)
    end

    # Sanity check to help ensure a valid test
    expect(success).not_to be_nil
    expect(primary_missing_file).not_to be_nil
  end
end
