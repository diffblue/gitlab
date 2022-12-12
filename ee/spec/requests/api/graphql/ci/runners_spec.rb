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

      post_graphql(query, current_user: current_user)
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
  end
end
