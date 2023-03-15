# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StatusPage::MarkForPublicationService, feature_category: :incident_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project, refind: true) { create(:project, group: group) }
  let_it_be(:issue, refind: true) { create(:issue, project: project) }

  let(:service) { described_class.new(project, user, issue) }

  before do
    stub_licensed_features(status_page: true)
    group.add_owner(user)
  end

  describe '#execute' do
    subject { service.execute }

    shared_examples 'does not track the incident' do
      specify { expect { subject }.not_to change { ::StatusPage::PublishedIncident.count } }
      specify { expect { subject }.not_to change { issue.notes.count } }

      it 'returns the exepected error state' do
        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

        expect(subject).to be_error
      end
    end

    context 'when license is not available' do
      before do
        stub_licensed_features(status_page: false)
      end

      it_behaves_like 'does not track the incident'
    end

    context 'when status page does not exist' do
      it_behaves_like 'does not track the incident'
    end

    context 'when status page is disabled' do
      let_it_be(:status_page_setting) { create(:status_page_setting, project: project) }

      it_behaves_like 'does not track the incident'
    end

    context 'when status page is enabled' do
      let_it_be(:status_page_setting) { create(:status_page_setting, :enabled, project: project) }

      context 'when issue is publishable' do
        specify { expect { subject }.to change { ::StatusPage::PublishedIncident.count }.by(1) }
        specify { expect { subject }.to change { issue.notes.count }.by(1) }
        specify { expect(subject).to be_success }

        it 'increments the publish counter' do
          expect(Gitlab::StatusPage::UsageDataCounters::IncidentCounter).to receive(:count).with(:publishes).once

          subject
        end
      end

      context 'when issue is confidential' do
        let_it_be(:issue) { create(:issue, :confidential, project: project) }

        it_behaves_like 'does not track the incident'
      end

      context 'when issue is already published' do
        let_it_be(:incident) { create(:status_page_published_incident, issue: issue) }

        it_behaves_like 'does not track the incident'
      end

      context 'when user is not logged in' do
        let(:service) { described_class.new(project, nil, issue) }

        it_behaves_like 'does not track the incident'
      end

      context 'when user does not have permissions' do
        let(:service) { described_class.new(project, create(:user), issue) }

        it_behaves_like 'does not track the incident'
      end

      context 'when an error occurs' do
        let(:error) { RuntimeError.new('Error!') }

        before do
          allow(::SystemNoteService).to receive(:publish_issue_to_status_page).and_raise(error)
        end

        specify { expect { subject }.not_to change { ::StatusPage::PublishedIncident.count } }
        specify { expect { subject }.not_to change { issue.notes.count } }

        it 'returns the exepected error state and reports the error to sentry' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(error)

          expect(subject).to be_error
        end
      end
    end
  end
end
