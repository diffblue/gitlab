# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Query.runners', feature_category: :runner_fleet do
  include GraphqlHelpers
  include RunnerReleasesHelper

  let_it_be(:current_user) { create_default(:user, :admin) }

  describe 'Query.runners' do
    let_it_be(:project) { create(:project, :repository, :public) }
    let_it_be(:instance_runner) { create(:ci_runner, :instance, version: '14.0.0') }
    let_it_be(:project_runner) { create(:ci_runner, :project, version: '14.0.1', projects: [project]) }

    let(:runners_graphql_data) { graphql_data['runners'] }
    let(:params) { {} }
    let(:runner_upgrade_management) { false }

    before do
      stub_runner_releases(%w[14.0.0 14.0.1])
    end

    context 'with upgradeStatus argument' do
      let(:upgrade_statuses) { runners_graphql_data['nodes'].map { |n| n['upgradeStatus'] } }
      let(:query) do
        %(
           query getRunners($upgradeStatus: #{upgrade_status_graphql_type}) {
             runners(upgradeStatus: $upgradeStatus) {
               nodes {
                 id
                 upgradeStatus
               }
             }
           }
         )
      end

      before do
        post_graphql(query, current_user: current_user)
      end

      context 'with deprecated CiRunnerUpgradeStatusType enum type' do
        let(:upgrade_status_graphql_type) { 'CiRunnerUpgradeStatusType' }

        it 'returns nil upgradeStatus for all runners' do
          expect(upgrade_statuses).to match_array([nil] * Ci::Runner.count)
        end
      end

      context 'with new CiRunnerUpgradeStatus enum type' do
        let(:upgrade_status_graphql_type) { 'CiRunnerUpgradeStatus' }

        it 'returns nil upgradeStatus for all runners' do
          expect(upgrade_statuses).to match_array([nil] * Ci::Runner.count)
        end
      end
    end

    context 'with membership argument' do
      let_it_be(:group) { create(:group) }
      let_it_be(:sub_group) { create(:group, parent: group) }
      let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }
      let_it_be(:sub_group_runner) { create(:ci_runner, :group, groups: [sub_group]) }

      let(:runner_ids) { graphql_data['group']['runners']['nodes'].map { |n| n['id'] } }
      let(:query) do
        %(
           query getGroupRunners($membership: #{membership_graphql_type}) {
             group(fullPath: "#{group.full_path}") {
               runners(membership: $membership) {
                 nodes {
                   id
                 }
               }
             }
           }
         )
      end

      before do
        post_graphql(query, current_user: current_user)
      end

      context 'with deprecated RunnerMembershipFilter enum type' do
        let(:membership_graphql_type) { 'RunnerMembershipFilter' }

        it 'returns ids of expected runners' do
          expect(runner_ids).to match_array([group_runner, sub_group_runner].map { |g| g.to_global_id.to_s })
        end
      end

      context 'with new CiRunnerMembershipFilter enum type' do
        let(:membership_graphql_type) { 'CiRunnerMembershipFilter' }

        it 'returns ids of expected runners' do
          expect(runner_ids).to match_array([group_runner, sub_group_runner].map { |g| g.to_global_id.to_s })
        end
      end
    end

    context 'when sorting by MOST_ACTIVE_DESC' do
      let_it_be(:runners) { create_list(:ci_runner, 6) }

      before_all do
        runners.map.with_index do |runner, number_of_builds|
          create_list(:ci_build, number_of_builds, runner: runner, project: project).each do |build|
            create(:ci_running_build, runner: build.runner, build: build, project: project)
          end
        end
      end

      it_behaves_like 'sorted paginated query' do
        before do
          stub_licensed_features(runner_performance_insights: true)
        end

        def pagination_query(params)
          graphql_query_for(:runners, params.merge(type: :INSTANCE_TYPE), "#{page_info} nodes { id }")
        end

        def pagination_results_data(runners)
          runners.map { |runner| GitlabSchema.parse_gid(runner['id'], expected_type: ::Ci::Runner).model_id.to_i }
        end

        let(:sort_param) { :MOST_ACTIVE_DESC }
        let(:first_param) { 2 }
        let(:all_records) { runners[1..5].reverse.map(&:id) }
        let(:data_path) { [:runners] }
      end

      it 'when requesting not instance_type runners' do
        stub_licensed_features(runner_performance_insights: true)
        query = graphql_query_for(:runners, { type: :GROUP_TYPE, sort: :MOST_ACTIVE_DESC }, "nodes { id }")
        post_graphql(query, current_user: current_user)

        expect(graphql_errors).to include(a_hash_including(
          'message' => 'MOST_ACTIVE_DESC sorting is only available when type is INSTANCE_TYPE'))
      end

      it 'when requesting not runners without type' do
        stub_licensed_features(runner_performance_insights: true)
        query = graphql_query_for(:runners, { sort: :MOST_ACTIVE_DESC }, "nodes { id }")
        post_graphql(query, current_user: current_user)

        expect(graphql_errors).to include(a_hash_including(
          'message' => 'MOST_ACTIVE_DESC sorting is only available when type is INSTANCE_TYPE'))
      end

      it 'returns error when feature is not enabled' do
        query = graphql_query_for(:runners, params.merge(type: :INSTANCE_TYPE, sort: :MOST_ACTIVE_DESC), "nodes { id }")
        post_graphql(query, current_user: current_user)

        expect(graphql_errors).to include(a_hash_including(
          'message' => 'runner_performance_insights feature is required for MOST_ACTIVE_DESC sorting'))
      end
    end
  end
end
