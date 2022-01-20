# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::FileUploadService do
  include EE::GeoHelpers

  let_it_be(:node) { create(:geo_node, :primary) }

  before do
    stub_current_geo_node(node)
  end

  describe '#retriever' do
    Gitlab::Geo::Replication::USER_UPLOADS_OBJECT_TYPES.each do |file_type|
      it "returns a FileRetriever given type is #{file_type}" do
        subject = described_class.new({ type: file_type, id: 1 }, 'request-data')

        expect(subject.retriever).to be_a(Gitlab::Geo::Replication::FileRetriever)
      end
    end

    it "returns a JobArtifactRetriever given object_type is job_artifact" do
      subject = described_class.new({ type: 'job_artifact', id: 1 }, 'request-data')

      expect(subject.retriever).to be_a(Gitlab::Geo::Replication::JobArtifactRetriever)
    end
  end

  shared_examples 'no decoded params' do
    it 'returns invalid request error' do
      service = described_class.new(params, nil)

      response = service.execute
      expect(response[:code]).to eq(:not_found)
      expect(response[:message]).to eq('Invalid request')
    end
  end

  describe '#execute' do
    context 'user avatar' do
      let(:user) { create(:user, avatar: fixture_file_upload('spec/fixtures/dk.png', 'image/png')) }
      let(:upload) { Upload.find_by(model: user, uploader: 'AvatarUploader') }
      let(:params) { { id: upload.id, type: 'avatar' } }
      let(:request_data) { Gitlab::Geo::Replication::FileTransfer.new(:avatar, upload).request_data }

      it 'sends avatar file' do
        service = described_class.new(params, request_data)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to eq(user.avatar.path)
      end

      include_examples 'no decoded params'
    end

    context 'group avatar' do
      let(:group) { create(:group, avatar: fixture_file_upload('spec/fixtures/dk.png', 'image/png')) }
      let(:upload) { Upload.find_by(model: group, uploader: 'AvatarUploader') }
      let(:params) { { id: upload.id, type: 'avatar' } }
      let(:request_data) { Gitlab::Geo::Replication::FileTransfer.new(:avatar, upload).request_data }

      it 'sends avatar file' do
        service = described_class.new(params, request_data)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to eq(group.avatar.path)
      end

      include_examples 'no decoded params'
    end

    context 'project avatar' do
      let(:project) { create(:project, avatar: fixture_file_upload('spec/fixtures/dk.png', 'image/png')) }
      let(:upload) { Upload.find_by(model: project, uploader: 'AvatarUploader') }
      let(:params) { { id: upload.id, type: 'avatar' } }
      let(:request_data) { Gitlab::Geo::Replication::FileTransfer.new(:avatar, upload).request_data }

      it 'sends avatar file' do
        service = described_class.new(params, request_data)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to eq(project.avatar.path)
      end

      include_examples 'no decoded params'
    end

    context 'attachment' do
      let(:note) { create(:note, :with_attachment) }
      let(:upload) { Upload.find_by(model: note, uploader: 'AttachmentUploader') }
      let(:params) { { id: upload.id, type: 'attachment' } }
      let(:request_data) { Gitlab::Geo::Replication::FileTransfer.new(:attachment, upload).request_data }

      it 'sends attachment file' do
        service = described_class.new(params, request_data)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to eq(note.attachment.path)
      end

      include_examples 'no decoded params'
    end

    context 'file upload' do
      let(:project) { create(:project) }
      let(:upload) { Upload.find_by(model: project, uploader: 'FileUploader') }
      let(:params) { { id: upload.id, type: 'file' } }
      let(:request_data) { Gitlab::Geo::Replication::FileTransfer.new(:file, upload).request_data }
      let(:file) { fixture_file_upload('spec/fixtures/dk.png', 'image/png') }

      before do
        FileUploader.new(project).store!(file)
      end

      it 'sends the file' do
        service = described_class.new(params, request_data)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to end_with('dk.png')
      end

      include_examples 'no decoded params'
    end

    context 'namespace file upload' do
      let(:group) { create(:group) }
      let(:upload) { Upload.find_by(model: group, uploader: 'NamespaceFileUploader') }
      let(:params) { { id: upload.id, type: 'file' } }
      let(:request_data) { Gitlab::Geo::Replication::FileTransfer.new(:file, upload).request_data }
      let(:file) { fixture_file_upload('spec/fixtures/dk.png', 'image/png') }

      before do
        NamespaceFileUploader.new(group).store!(file)
      end

      it 'sends the file' do
        service = described_class.new(params, request_data)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to end_with('dk.png')
      end

      include_examples 'no decoded params'
    end

    context 'incident metrics upload' do
      let(:incident_metric_image) { create(:issuable_metric_image) }
      let(:upload) { Upload.find_by(model: incident_metric_image, uploader: ::IssuableMetricImageUploader.name) }
      let(:params) { { id: upload.id, type: 'issuable_metric_image' } }
      let(:request_data) { Gitlab::Geo::Replication::FileTransfer.new(:file, upload).request_data }

      it 'sends the file' do
        service = described_class.new(params, request_data)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to eq(incident_metric_image.file.path)
      end

      include_examples 'no decoded params'
    end

    context 'job artifact' do
      let(:job_artifact) { create(:ci_job_artifact, :with_file) }
      let(:params) { { id: job_artifact.id, type: 'job_artifact' } }
      let(:request_data) { Gitlab::Geo::Replication::JobArtifactTransfer.new(job_artifact).request_data }

      it 'sends job artifact file' do
        service = described_class.new(params, request_data)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to eq(job_artifact.file.path)
      end
    end

    context 'import export archive' do
      let(:project) { create(:project) }
      let(:upload) { Upload.find_by(model: project, uploader: 'ImportExportUploader') }
      let(:params) { { id: upload.id, type: 'import_export' } }
      let(:request_data) { Gitlab::Geo::Replication::FileTransfer.new(:import_export, upload).request_data }
      let(:file) { fixture_file_upload('spec/fixtures/project_export.tar.gz') }

      before do
        ImportExportUploader.new(project).store!(file)
      end

      it 'sends the file' do
        service = described_class.new(params, request_data)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to end_with('tar.gz')
      end

      include_examples 'no decoded params'
    end

    context 'bulk imports export file' do
      let_it_be(:type) { :'bulk_imports/export' }
      let_it_be(:export) { create(:bulk_import_export) }
      let_it_be(:file) { fixture_file_upload('spec/fixtures/bulk_imports/gz/labels.ndjson.gz') }

      let(:upload) { Upload.find_by(model: export, uploader: 'BulkImports::ExportUploader') }
      let(:request_data) { Gitlab::Geo::Replication::FileTransfer.new(type, upload).request_data }
      let(:params) { { id: upload.id, type: type } }

      before do
        BulkImports::ExportUploader.new(export).store!(file)
      end

      it 'sends the file' do
        service = described_class.new(params, request_data)

        response = service.execute

        expect(response[:code]).to eq(:ok)
        expect(response[:file].path).to end_with('ndjson.gz')
      end

      include_examples 'no decoded params'
    end
  end
end
