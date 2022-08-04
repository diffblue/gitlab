# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Query.runners' do
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
    let(:runner_releases_double) { instance_double(Gitlab::Ci::RunnerReleases) }
    let(:available_runner_releases) do
      %w[14.0.0 14.0.1]
    end

    before do
      stub_runner_releases(runner_releases_double, available_runner_releases, gitlab_version: '14.0.1')

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
  end
end
