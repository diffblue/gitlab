# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StatusPage::UnpublishDetailsService, feature_category: :incident_management do
  let_it_be(:project, refind: true) { create(:project) }

  let(:issue) { instance_double(Issue, iid: incident_id) }
  let(:incident_id) { 1 }
  let(:key) { Gitlab::StatusPage::Storage.details_path(incident_id) }
  let(:image_uploads_path) { Gitlab::StatusPage::Storage.uploads_path(issue.iid) }

  let(:service) { described_class.new(project: project) }

  subject(:result) { service.execute(issue) }

  describe '#execute' do
    let(:status_page_setting_enabled) { true }
    let(:storage_client) { instance_double(Gitlab::StatusPage::Storage::S3Client) }

    let(:status_page_setting) do
      instance_double(StatusPage::ProjectSetting, enabled?: status_page_setting_enabled, storage_client: storage_client)
    end

    before do
      stub_licensed_features(status_page: true)

      allow(project).to receive(:status_page_setting)
        .and_return(status_page_setting)

      allow(StatusPage::PublishedIncident).to receive(:find_by)
        .with(issue: issue)
        .and_return(nil)
    end

    context 'when deletion succeeds' do
      before do
        allow(storage_client).to receive(:delete_object).with(key)
        allow(storage_client).to receive(:recursive_delete).with(image_uploads_path)
      end

      it 'removes files from the CDN (incident first)' do
        expect(storage_client).to receive(:delete_object).ordered
        expect(storage_client).to receive(:recursive_delete).with(image_uploads_path).ordered

        result
      end

      it 'returns service success' do
        expect(result).to be_success
        expect(result.payload).to eq(object_key: key)
      end

      it 'untracks the issue' do
        expect(StatusPage::PublishedIncident).to receive(:untrack).with(issue)
        expect(Gitlab::StatusPage::UsageDataCounters::IncidentCounter).to receive(:count).with(:unpublishes).once

        result
      end
    end

    context 'when delete fails due to exception' do
      let(:bucket) { 'bucket_name' }
      let(:error) { StandardError.new }

      let(:exception) do
        Gitlab::StatusPage::Storage::Error.new(bucket: bucket, error: error)
      end

      context 'when json delete fails' do
        before do
          allow(storage_client).to receive(:delete_object).with(key)
            .and_raise(exception)
          allow(storage_client).to receive(:recursive_delete)
        end

        it 'propagates the exception' do
          expect { result }.to raise_error(exception)
        end
      end

      context 'when image delete fails' do
        before do
          allow(storage_client).to receive(:delete_object)
          allow(storage_client).to receive(:recursive_delete).with(image_uploads_path)
            .and_raise(exception)
        end

        it 'propagates the exception' do
          expect { result }.to raise_error(exception)
        end
      end
    end

    context 'when status page setting is not enabled' do
      let(:status_page_setting_enabled) { false }

      it 'returns feature not available error' do
        expect(result).to be_error
        expect(result.message).to eq('Feature not available')
      end
    end
  end
end
