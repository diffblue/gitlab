# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ContributionAnalyticsController, feature_category: :value_stream_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:user3) { create(:user) }
  let_it_be(:guest_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:merge_request) { create(:merge_request, :simple, source_project: project) }

  let(:push_data) { Gitlab::DataBuilder::Push.build_sample(project, user) }

  def create_event(author, project, target, action)
    Event.create!(
      project: project,
      action: action,
      target: target,
      author: author,
      created_at: Time.current)
  end

  def create_push_event(author, project)
    event = create_event(author, project, nil, :pushed)
    PushEventPayloadService.new(event, push_data).execute
  end

  before do
    group.add_owner(user)
    group.add_member(user2, GroupMember::DEVELOPER)
    group.add_member(user3, GroupMember::MAINTAINER)
  end

  describe '#authorize_read_contribution_analytics!' do
    let(:request) { get :show, params: { group_id: group.path } }

    context 'when feature is available to the group' do
      before do
        stub_licensed_features(contribution_analytics: true)
      end

      context 'when user is an auditor' do
        let(:auditor) { create(:user, :auditor) }

        it 'allows access' do
          sign_in(auditor)

          request

          expect(response).to have_gitlab_http_status(:success)
        end
      end

      context 'when user has access to the group' do
        before do
          group.add_member(guest_user, GroupMember::GUEST)
          sign_in(guest_user)

          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?)
            .with(guest_user, :read_group_contribution_analytics, group)
            .and_return(user_has_access_to_feature)
        end

        context 'when user has access to the feature' do
          let(:user_has_access_to_feature) { true }

          it 'renders 200' do
            request

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'when user does not have access to the feature' do
          let(:user_has_access_to_feature) { false }

          it 'renders 404' do
            request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end

    describe '#check_contribution_analytics_available!' do
      before do
        group.add_member(guest_user, GroupMember::GUEST)
        sign_in(guest_user)
      end

      context 'when feature is not available to the group' do
        let(:request) { get :show, params: { group_id: group.path } }

        before do
          allow(License).to receive(:feature_available?).and_call_original
          allow(License).to receive(:feature_available?)
            .with(:contribution_analytics)
            .and_return(false)
        end

        it 'renders 404' do
          request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'with contributions' do
    before do
      sign_in(user)

      create_event(user, project, issue, :closed)
      create_event(user2, project, issue, :closed)
      create_event(user2, project, merge_request, :created)
      create_event(user3, project, merge_request, :created)
      create_push_event(user, project)
      create_push_event(user3, project)
    end

    it 'sets instance variables properly', :aggregate_failures do
      get :show, params: { group_id: group.path }

      expect(response).to have_gitlab_http_status(:ok)

      expect(assigns[:data_collector].users).to match_array([user, user2, user3])
      expect(assigns[:data_collector].total_events_by_author_count.values.sum).to eq(6)
    end

    it "returns member contributions JSON when format is JSON" do
      get :show, params: { group_id: group.path }, format: :json

      expect(json_response.length).to eq(3)

      first_user = json_response.at(0)
      expect(first_user["username"]).to eq(user.username)
      expect(first_user["user_web_url"]).to eq("/#{user.username}")
      expect(first_user["fullname"]).to eq(user.name)
      expect(first_user["push"]).to eq(1)
      expect(first_user["issues_created"]).to eq(0)
      expect(first_user["issues_closed"]).to eq(1)
      expect(first_user["merge_requests_created"]).to eq(0)
      expect(first_user["merge_requests_merged"]).to eq(0)
      expect(first_user["total_events"]).to eq(2)
    end

    it "includes projects in subgroups" do
      subgroup = create(:group, parent: group)
      subproject = create(:project, :repository, group: subgroup)

      create_event(user, subproject, issue, :closed)
      create_push_event(user, subproject)

      get :show, params: { group_id: group.path }, format: :json

      first_user = json_response.first
      expect(first_user["issues_closed"]).to eq(2)
      expect(first_user["push"]).to eq(2)
    end

    it "excludes projects outside of the group" do
      empty_group = create(:group)
      other_project = create(:project, :repository)

      empty_group.add_reporter(user)

      create_event(user, other_project, issue, :closed)
      create_push_event(user, other_project)

      get :show, params: { group_id: empty_group.path }, format: :json

      expect(json_response).to be_empty
    end

    it 'does not cause N+1 queries when the format is JSON' do
      control_count = ActiveRecord::QueryRecorder.new do
        get :show, params: { group_id: group.path }, format: :json
      end

      controller.instance_variable_set(:@group, nil)
      user4 = create(:user)
      group.add_member(user4, GroupMember::DEVELOPER)

      expect { get :show, params: { group_id: group.path }, format: :json }
        .not_to exceed_query_limit(control_count)
    end

    describe 'with views' do
      render_views

      it 'avoids a N+1 query in #show' do
        # Warm the cache
        get :show, params: { group_id: group.path }

        control_queries = ActiveRecord::QueryRecorder.new { get :show, params: { group_id: group.path } }
        create_push_event(user, project)

        expect { get :show, params: { group_id: group.path } }.not_to exceed_query_limit(control_queries)
      end
    end

    describe 'GET #show' do
      subject { get :show, params: { group_id: group.to_param } }

      it_behaves_like 'disabled when using an external authorization service'

      it_behaves_like 'tracking unique visits', :show do
        let(:request_params) { { group_id: group.to_param } }
        let(:target_id) { 'g_analytics_contribution' }
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context', overrides: { project: nil } do
        let(:category) { described_class.name }
        let(:action) { 'perform_analytics_usage_action' }
        let(:label) { 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly' }
        let(:property) { 'g_analytics_contribution' }
        let(:namespace) { group }
      end
    end
  end
end
