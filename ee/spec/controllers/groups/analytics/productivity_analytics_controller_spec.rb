# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Analytics::ProductivityAnalyticsController, feature_category: :team_planning do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create :group }

  before do
    sign_in(current_user)

    stub_licensed_features(productivity_analytics: true)
  end

  describe 'usage counter' do
    before do
      group.add_owner(current_user)
    end

    it 'increments usage counter' do
      expect(Gitlab::UsageDataCounters::ProductivityAnalyticsCounter).to receive(:count).with(:views)

      get :show, format: :html, params: { group_id: group }

      expect(response).to be_successful
    end

    it "doesn't increment the usage counter when JSON request is sent" do
      expect(Gitlab::UsageDataCounters::ProductivityAnalyticsCounter).not_to receive(:count).with(:views)

      get :show, format: :json, params: { group_id: group }

      expect(response).to be_successful
    end
  end

  describe 'GET show' do
    subject { get :show, params: { group_id: group } }

    context 'when user is not authorized to view productivity analytics' do
      before do
        expect(Ability).to receive(:allowed?).with(current_user, :log_in, :global).and_call_original
        expect(Ability).to receive(:allowed?).with(current_user, :read_group, group).and_return(true)
        expect(Ability).to receive(:allowed?).with(current_user, :view_productivity_analytics, group).and_return(false)
      end

      it 'renders 403, forbidden error' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when feature is not licensed' do
      before do
        stub_licensed_features(productivity_analytics: false)
      end

      it 'renders forbidden error' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when the feature is licensed' do
      before do
        stub_licensed_features(productivity_analytics: true)
        group.add_owner(current_user)
      end

      it_behaves_like 'tracking unique visits', :show do
        let(:request_params) { { group_id: group } }
        let(:target_id) { 'g_analytics_productivity' }
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        subject { get :show, params: { group_id: group } }

        let(:category) { described_class.name }
        let(:action) { 'perform_analytics_usage_action' }
        let(:label) { 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly' }
        let(:property) { 'g_analytics_productivity' }
        let(:user) { current_user }
        let(:namespace) { group }
      end
    end

    context 'when user is an auditor' do
      let(:current_user) { create(:user, :auditor) }

      it 'allows access' do
        subject

        expect(response).to have_gitlab_http_status(:success)
      end
    end
  end

  describe 'GET show.json' do
    subject { get :show, format: :json, params: params }

    let(:params) { { group_id: group } }
    let(:analytics_mock) { instance_double('ProductivityAnalytics') }

    before do
      merge_requests = double
      allow_next_instance_of(ProductivityAnalyticsFinder) do |instance|
        allow(instance).to receive(:execute).and_return(merge_requests)
      end
      allow(ProductivityAnalytics)
        .to receive(:new)
              .with(merge_requests: merge_requests, sort: params[:sort])
              .and_return(analytics_mock)
    end

    context 'when feature is not licensed' do
      before do
        stub_licensed_features(productivity_analytics: false)
      end

      it 'renders forbidden error' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when invalid params are given' do
      let(:params) { { group_id: group, merged_before: 10.days.ago, merged_after: 5.days.ago } }

      before do
        group.add_owner(current_user)
      end

      it 'returns 422, unprocessable_entity' do
        subject

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(response).to match_response_schema('analytics/cycle_analytics/validation_error', dir: 'ee')
      end
    end

    context 'without group_id specified' do
      it 'renders 403, forbidden' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with non-existing group_id' do
      let(:params) { { group_id: 'SOMETHING_THAT_DOES_NOT_EXIST' } }

      it 'renders 404, not_found' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with non-existing project_id' do
      let(:params) { { group_id: group, project_id: 'SOMETHING_THAT_DOES_NOT_EXIST' } }

      it 'renders 404, not_found' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with group specified' do
      let(:params) { { group_id: group } }

      before do
        group.add_owner(current_user)
      end

      context 'for list of MRs' do
        let!(:merge_request) { create :merge_request, :merged }

        let(:serializer_mock) { instance_double('BaseSerializer') }

        before do
          allow(BaseSerializer).to receive(:new).with(current_user: current_user).and_return(serializer_mock)
          allow(analytics_mock).to receive(:merge_requests_extended).and_return(MergeRequest.all)
          allow(serializer_mock).to receive(:represent)
                                      .with(merge_request, {}, ProductivityAnalyticsMergeRequestEntity)
                                      .and_return('mr_representation')
        end

        it 'serializes whatever analytics returns with ProductivityAnalyticsMergeRequestEntity' do
          subject

          expect(response.body).to eq '["mr_representation"]'
        end

        it 'sets pagination headers' do
          subject

          expect(response.headers['X-Per-Page']).to eq '20'
          expect(response.headers['X-Page']).to eq '1'
          expect(response.headers['X-Next-Page']).to eq ''
          expect(response.headers['X-Prev-Page']).to eq ''
          expect(response.headers['X-Total']).to eq '1'
          expect(response.headers['X-Total-Pages']).to eq '1'
        end

        context 'when project from a sub-group is requested' do
          let(:subgroup) { create(:group, parent: group) }
          let(:project) { create(:project, group: subgroup) }

          let(:params) { { group_id: group, project_id: project.full_path } }

          before do
            group.add_owner(current_user)
          end

          it 'succeeds' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      context 'for scatterplot charts' do
        let(:params) { super().merge({ chart_type: 'scatterplot', metric_type: 'commits_count' }) }

        it 'renders whatever analytics returns for scatterplot' do
          allow(analytics_mock).to receive(:scatterplot_data).with(type: 'commits_count').and_return('scatterplot_data')

          subject

          expect(response.body).to eq 'scatterplot_data'
        end
      end

      context 'for histogram charts' do
        let(:params) { super().merge({ chart_type: 'histogram', metric_type: 'commits_count' }) }

        it 'renders whatever analytics returns for histogram' do
          allow(analytics_mock).to receive(:histogram_data).with(type: 'commits_count').and_return('histogram_data')

          subject

          expect(response.body).to eq 'histogram_data'
        end
      end
    end
  end
end
