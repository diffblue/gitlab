# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IncidentsHelper do
  include Gitlab::Routing.url_helpers

  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }
  let(:project_path) { project.full_path }
  let(:new_issue_path) { new_project_issue_path(project) }
  let(:issue_path) { project_issues_path(project) }
  let(:params) do
    {
      search: 'search text',
      author_username: 'root',
      assignee_username: 'max.power'
    }
  end

  before do
    allow(helper).to receive(:current_user).and_return(user)
    allow(helper).to receive(:can?)
      .with(user, :create_incident, project)
      .and_return(true)
  end

  describe '#incidents_data' do
    let(:expected_incidents_data) do
      {
        'project-path' => project_path,
        'new-issue-path' => new_issue_path,
        'incident-template-name' => 'incident',
        'incident-type' => 'incident',
        'issue-path' => issue_path,
        'empty-list-svg-path' => match_asset_path('/assets/illustrations/incident-empty-state.svg'),
        'published-available' => 'false',
        'sla-feature-available' => 'false',
        'text-query': 'search text',
        'author-username-query': 'root',
        'assignee-username-query': 'max.power',
        'can-create-incident': 'true'
      }
    end

    subject { helper.incidents_data(project, params) }

    it 'returns the correct set of data' do
      expect(subject).to match(expected_incidents_data)
    end

    context 'when status page feature is available' do
      before do
        stub_licensed_features(status_page: true)
      end

      it 'returns the feature as enabled' do
        expect(subject['published-available']).to eq('true')
      end
    end

    context 'when status page feature is not available' do
      before do
        stub_licensed_features(status_page: false)
      end

      it 'returns the feature as disabled' do
        expect(subject['published-available']).to eq('false')
      end
    end

    context 'when incident sla feature is available' do
      before do
        stub_licensed_features(incident_sla: true)
      end

      it 'returns the feature as enabled' do
        expect(subject['sla-feature-available']).to eq('true')
      end
    end

    context 'when incident sla feature is not available' do
      before do
        stub_licensed_features(incident_sla: false)
      end

      it 'returns the feature as disabled' do
        expect(subject['sla-feature-available']).to eq('false')
      end
    end
  end
end
