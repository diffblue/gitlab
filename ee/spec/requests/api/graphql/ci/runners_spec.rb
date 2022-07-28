# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Query.runners' do
  include GraphqlHelpers

  let_it_be(:current_user) { create_default(:user, :admin) }

  describe 'Query.runners' do
    let_it_be(:project) { create(:project, :repository, :public) }
    let_it_be(:instance_runner) { create(:ci_runner, :instance, version: 'abc') }
    let_it_be(:project_runner) { create(:ci_runner, :project, version: 'def', projects: [project]) }

    let(:runners_graphql_data) { graphql_data['runners'] }

    let(:params) { {} }

    before do
      allow(Gitlab::Ci::RunnerUpgradeCheck.instance).to receive(:check_runner_upgrade_suggestion)

      post_graphql(query, current_user: current_user)
    end

    context 'with upgradeStatus argument' do
      let(:upgrade_statuses) { runners_graphql_data['nodes'].map { |n| n['upgradeStatus'] } }
      let(:query) do
        %(
            query getRunners($upgradeStatus: #{upgrade_status_graphql_type}) {
              runners(upgradeStatus: $upgradeStatus) {
                nodes {
                  upgradeStatus
                }
              }
            }
          )
      end

      context 'with deprecated CiRunnerUpgradeStatusType enum type' do
        let(:upgrade_status_graphql_type) { 'CiRunnerUpgradeStatusType' }

        it 'returns upgradeStatus for all runners' do
          expect(upgrade_statuses).to match_array([nil] * Ci::Runner.count)
        end
      end

      context 'with new CiRunnerUpgradeStatus enum type' do
        let(:upgrade_status_graphql_type) { 'CiRunnerUpgradeStatus' }

        it 'returns upgradeStatus for all runners' do
          expect(upgrade_statuses).to match_array([nil] * Ci::Runner.count)
        end
      end
    end
  end
end
