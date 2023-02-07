# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::StatusPage::Storage::S3MultipartUpload, :aws_s3 do
  let(:region) { 'eu-west-1' }
  let(:bucket_name) { 'bucket_name' }
  let(:access_key_id) { 'key_id' }
  let(:secret_access_key) { 'secret' }

  let(:s3_client) do
    Aws::S3::Client.new(
      region: region,
      credentials: Aws::Credentials.new(access_key_id, secret_access_key)
    )
  end

  describe '#call' do
    let(:key) { '123' }
    let(:file) do
      Tempfile.new('foo').tap do |file|
        file.open
        file.write('hello world')
        file.rewind
      end
    end

    let(:upload_id) { '123456789' }

    subject(:result) { described_class.new(client: s3_client, bucket_name: bucket_name, key: key, open_file: file).call }

    before do
      stub_responses(
        :create_multipart_upload,
        instance_double(Aws::S3::Types::CreateMultipartUploadOutput, { to_h: { upload_id: upload_id } })
      )
    end

    after do
      file.close
    end

    context 'when sucessful' do
      before do
        stub_responses(
          :upload_part,
          instance_double(Aws::S3::Types::UploadPartOutput, to_h: {})
        )
      end

      it 'completes' do
        expect(s3_client).to receive(:complete_multipart_upload)

        result
      end

      context 'with more than one part' do
        before do
          stub_const("#{described_class}::MULTIPART_UPLOAD_PART_SIZE", 1.byte)
        end

        it 'completes' do
          # Ensure size limit triggers more than one part upload
          expect(s3_client).to receive(:upload_part).at_least(:twice)
          expect(s3_client).to receive(:complete_multipart_upload)

          result
        end
      end
    end

    context 'when fails' do
      let(:aws_error) { 'SomeError' }

      context 'on upload part' do
        before do
          stub_responses(:upload_part, aws_error)
        end

        it 'aborts the upload and raises an error' do
          msg = error_message(aws_error, key: key)

          expect(s3_client).to receive(:abort_multipart_upload)
          expect { result }.to raise_error(Gitlab::StatusPage::Storage::Error, msg)
        end
      end

      context 'on complete_multipart_upload' do
        before do
          stub_responses(:upload_part, {})
          stub_responses(:complete_multipart_upload, aws_error)
        end

        it 'aborts the upload and raises an error' do
          msg = error_message(aws_error, key: key)

          expect(s3_client).to receive(:abort_multipart_upload)
          expect { result }.to raise_error(Gitlab::StatusPage::Storage::Error, msg)
        end
      end
    end
  end

  private

  def stub_responses(...)
    s3_client.stub_responses(...)
  end

  def error_message(error_class, **args)
    %{Error occurred "Aws::S3::Errors::#{error_class}" } \
      "for bucket #{bucket_name.inspect}. Arguments: #{args.inspect}"
  end
end
