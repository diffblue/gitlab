# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.runner(id)' do
  include GraphqlHelpers

  let_it_be(:admin) { create(:user, :admin) }

  shared_examples 'runner details fetch operation returning expected upgradeStatus' do
    let(:query) do
      wrap_fields(query_graphql_path(query_path, 'id upgradeStatus'))
    end

    let(:query_path) do
      [
        [:runner, { id: runner.to_global_id.to_s }]
      ]
    end

    before do
      allow(::Gitlab::Ci::RunnerUpgradeCheck.instance)
        .to receive(:check_runner_upgrade_status)
        .and_return({ upgrade_status => nil })
        .once
    end

    it 'retrieves expected fields' do
      post_graphql(query, current_user: current_user)

      runner_data = graphql_data_at(:runner)
      expect(runner_data).not_to be_nil

      expect(runner_data).to match a_hash_including(
        'id' => runner.to_global_id.to_s,
        'upgradeStatus' => expected_upgrade_status
      )
    end
  end

  describe 'upgradeStatus', :saas do
    let_it_be(:runner) { create(:ci_runner, description: 'Runner 1', version: '14.1.0', revision: 'a') }

    context 'requested by non-paid user' do
      let(:current_user) { admin }

      context 'with RunnerUpgradeCheck returning :available' do
        let(:upgrade_status) { :available }
        let(:expected_upgrade_status) { 'UNKNOWN' } # non-paying users always see UNKNOWN

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end
    end

    context 'requested on an instance with runner_upgrade_management' do
      let(:current_user) { admin }

      before do
        stub_licensed_features(runner_upgrade_management: true)
      end

      context 'with RunnerUpgradeCheck returning :error' do
        let(:upgrade_status) { :error }
        let(:expected_upgrade_status) { 'UNKNOWN' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'with RunnerUpgradeCheck returning :not_available' do
        let(:upgrade_status) { :not_available }
        let(:expected_upgrade_status) { 'NOT_AVAILABLE' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'with RunnerUpgradeCheck returning :available' do
        let(:upgrade_status) { :available }
        let(:expected_upgrade_status) { 'AVAILABLE' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'with RunnerUpgradeCheck returning :recommended' do
        let(:upgrade_status) { :recommended }
        let(:expected_upgrade_status) { 'RECOMMENDED' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'with RunnerUpgradeCheck returning :invalid_version' do
        let(:upgrade_status) { :invalid_version }
        let(:expected_upgrade_status) { 'INVALID' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end
    end

    context 'requested by paid user' do
      let_it_be(:ultimate_group) { create(:group_with_plan, plan: :ultimate_plan) }
      let_it_be(:user) { create(:user, :admin, namespace: create(:user_namespace)) }

      let(:current_user) { user }

      before do
        ultimate_group.add_reporter(user)
      end

      context 'with RunnerUpgradeCheck returning :not_available' do
        let(:upgrade_status) { :not_available }
        let(:expected_upgrade_status) { 'NOT_AVAILABLE' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'with RunnerUpgradeCheck returning :available' do
        let(:upgrade_status) { :available }
        let(:expected_upgrade_status) { 'AVAILABLE' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'with RunnerUpgradeCheck returning :recommended' do
        let(:upgrade_status) { :recommended }
        let(:expected_upgrade_status) { 'RECOMMENDED' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'integration test with Gitlab::Ci::RunnerUpgradeCheck' do
        let(:query) do
          wrap_fields(query_graphql_path(query_path, 'id upgradeStatus'))
        end

        let(:query_path) do
          [
            [:runner, { id: runner.to_global_id.to_s }]
          ]
        end

        let(:available_runner_releases) do
          %w[14.1.0 14.1.1]
        end

        before do
          url = ::Gitlab::CurrentSettings.current_application_settings.public_runner_releases_url

          WebMock.stub_request(:get, url).to_return(
            body: available_runner_releases.map { |v| { name: v } }.to_json,
            status: 200,
            headers: { 'Content-Type' => 'application/json' }
          )
        end

        it 'retrieves expected fields' do
          post_graphql(query, current_user: current_user)

          runner_data = graphql_data_at(:runner)
          expect(runner_data).not_to be_nil

          expect(runner_data).to match a_hash_including(
            'id' => runner.to_global_id.to_s,
            'upgradeStatus' => 'RECOMMENDED'
          )
        end
      end
    end
  end
end
