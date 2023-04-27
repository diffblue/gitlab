# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Dora::Metrics, feature_category: :dora_metrics do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:production) { create(:environment, :production, project: project) }
  let_it_be(:staging) { create(:environment, :staging, project: project) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:guest) { create(:user) }

  shared_examples 'common dora metrics endpoint' do
    using RSpec::Parameterized::TableSyntax

    let(:user) { maintainer }

    around do |example|
      travel_to '2021-01-03'.to_time do
        example.run
      end
    end

    before_all do
      create(:dora_daily_metrics,
             deployment_frequency: 1,
             lead_time_for_changes_in_seconds: 3,
             time_to_restore_service_in_seconds: 5,
             incidents_count: 7,
             environment: production,
             date: '2021-01-01')
      create(:dora_daily_metrics,
             deployment_frequency: 2,
             lead_time_for_changes_in_seconds: 4,
             time_to_restore_service_in_seconds: 6,
             incidents_count: 8,
             environment: production,
             date: '2021-01-02')
      create(:dora_daily_metrics,
             deployment_frequency: 100,
             lead_time_for_changes_in_seconds: 200,
             time_to_restore_service_in_seconds: 300,
             incidents_count: 400,
             environment: staging,
             date: '2021-01-02')
    end

    before do
      stub_licensed_features(dora4_analytics: true)
    end

    where(:metric, :value1, :value2) do
      :deployment_frequency    | 1  | 2
      :lead_time_for_changes   | 3  | 4
      :time_to_restore_service | 5  | 6
      :change_failure_rate     | 7  | 4
    end

    with_them do
      let(:params) { { metric: metric } }

      it 'returns data' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to match_array([{ 'date' => '2021-01-01', 'value' => value1 },
                                              { 'date' => '2021-01-02', 'value' => value2 }])
      end
    end

    context 'with multiple metrics' do
      let(:params) { { metric: 'deployment_frequency', environment_tiers: %w[production staging] } }

      it 'returns combined data' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to match_array([{ 'date' => '2021-01-01', 'value' => 1 },
                                              { 'date' => '2021-01-02', 'value' => 102 }])
      end
    end

    context 'when user is guest' do
      let(:user) { guest }
      let(:params) { { metric: :deployment_frequency } }

      it 'returns authorization error' do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(json_response['message']).to eq('You do not have permission to access dora metrics.')
      end
    end
  end

  describe 'GET /projects/:id/dora/metrics' do
    subject { get api("/projects/#{project.id}/dora/metrics", user), params: params }

    before_all do
      project.add_maintainer(maintainer)
      project.add_guest(guest)
    end

    include_examples 'common dora metrics endpoint'
  end

  describe 'GET /groups/:id/dora/metrics' do
    subject { get api("/groups/#{group.id}/dora/metrics", user), params: params }

    before_all do
      group.add_maintainer(maintainer)
      group.add_guest(guest)
    end

    include_examples 'common dora metrics endpoint'
  end
end
