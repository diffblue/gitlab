# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StatusPage::PublishAttachmentsService, feature_category: :incident_management do
  RSpec.shared_context 'second file' do
    # Setup second file
    let(:upload_secret_2) { '9cb61a79ce884d5b681dd42728d3c159' }
    let(:image_file_name_2) { 'tanuki_2.png' }
    let(:upload_path_2) { "/uploads/#{upload_secret_2}/#{image_file_name_2}" }
    let(:markdown_field) { "![tanuki](#{upload_path}) and ![tanuki_2](#{upload_path_2})" }
    let(:status_page_upload_path_2) { Gitlab::StatusPage::Storage.upload_path(issue.iid, upload_secret_2, image_file_name_2) }
  end

  describe '#execute' do
    let_it_be(:project, refind: true) { create(:project) }

    let(:markdown_field) { 'Hello World' }
    let(:user_notes) { [] }
    let(:incident_id) { 1 }
    let(:issue) { instance_double(Issue, notes: user_notes, description: markdown_field, iid: incident_id) }
    let(:key) { Gitlab::StatusPage::Storage.details_path(incident_id) }
    let(:content) { { id: incident_id } }
    let(:storage_client) { instance_double(Gitlab::StatusPage::Storage::S3Client) }

    let(:service) { described_class.new(project: project, issue: issue, user_notes: user_notes, storage_client: storage_client) }

    subject { service.execute }

    include_context 'stub status page enabled'

    context 'publishes file attachments' do
      before do
        allow(storage_client).to receive(:upload_object).with("data/incident/1.json", "{\"id\":1}")
        allow(storage_client).to receive(:list_object_keys).and_return(Set.new)
      end

      context 'when not in markdown' do
        it 'publishes no images' do
          expect(storage_client).not_to receive(:multipart_upload)
          expect(subject.payload).to eq({})
          expect(subject).to be_success
        end
      end

      context 'when in markdown' do
        let(:upload_secret) { '734b8524a16d44eb0ff28a2c2e4ff3c0' }
        let(:image_file_name) { 'tanuki.png' }
        let(:upload_path) { "/uploads/#{upload_secret}/#{image_file_name}" }
        let(:markdown_field) { "![tanuki](#{upload_path})" }
        let(:status_page_upload_path) { Gitlab::StatusPage::Storage.upload_path(issue.iid, upload_secret, image_file_name) }
        let(:user_notes) { [] }

        let(:open_file) { instance_double(File, read: 'stubbed read') }
        let(:uploader) { instance_double(FileUploader) }

        before do
          allow(uploader).to receive(:open).and_yield(open_file).twice

          allow_next_instance_of(UploaderFinder) do |finder|
            allow(finder).to receive(:execute).and_return(uploader)
          end

          allow(storage_client).to receive(:list_object_keys).and_return(Set[])
          allow(storage_client).to receive(:upload_object)
        end

        it 'publishes description images' do
          expect(storage_client).to receive(:multipart_upload).with(status_page_upload_path, open_file).once

          expect(subject).to be_success
          expect(subject.payload).to eq({})
        end

        context 'when upload to storage throws an error' do
          it 'returns an error response' do
            storage_error = Gitlab::StatusPage::Storage::Error.new(bucket: '', error: StandardError.new)
            # no raise to mimic prod behavior
            allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
            allow(storage_client).to receive(:multipart_upload).and_raise(storage_error)

            expect(subject.error?).to be true
          end
        end

        context 'user notes uploads' do
          let(:user_note) { instance_double(Note, note: markdown_field) }
          let(:user_notes) { [user_note] }
          let(:issue) { instance_double(Issue, notes: user_notes, description: '', iid: incident_id) }

          it 'publishes images' do
            expect(storage_client).to receive(:multipart_upload).with(status_page_upload_path, open_file).once

            expect(subject).to be_success
            expect(subject.payload).to eq({})
          end
        end

        context 'when exceeds upload limit' do
          include_context 'second file'

          before do
            stub_const("Gitlab::StatusPage::Storage::MAX_UPLOADS", 2)
            allow(storage_client).to receive(:list_object_keys).and_return(Set['existing_key'])
          end

          it 'publishes no images' do
            expect(storage_client).to receive(:multipart_upload).once

            expect(subject).to be_success
            expect(subject.payload).to eq({})
          end
        end

        context 'when all images are in s3' do
          before do
            allow(storage_client).to receive(:list_object_keys).and_return(Set[status_page_upload_path])
          end

          it 'publishes no images' do
            expect(storage_client).not_to receive(:multipart_upload)

            expect(subject).to be_success
            expect(subject.payload).to eq({})
          end
        end

        context 'when images are already in s3' do
          include_context 'second file'

          before do
            allow(storage_client).to receive(:list_object_keys).and_return(Set[status_page_upload_path])
          end

          it 'publishes only new images' do
            expect(storage_client).to receive(:multipart_upload).with(status_page_upload_path_2, open_file).once
            expect(storage_client).not_to receive(:multipart_upload).with(status_page_upload_path, open_file)

            expect(subject).to be_success
            expect(subject.payload).to eq({})
          end
        end
      end
    end
  end
end
