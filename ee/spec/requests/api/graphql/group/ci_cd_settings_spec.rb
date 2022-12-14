# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Ci/Cd settings through GroupQuery', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }

  let(:query) do
    graphql_query_for(
      'group',
      { 'fullPath' => group.full_path },
      'allowStaleRunnerPruning'
    )
  end

  subject(:request) { post_graphql(query) }

  let(:group_data) { graphql_data_at(:group) }

  context 'when group has no associated ci_cd_settings' do
    let(:group) { create(:group) }

    before do
      group.ci_cd_settings.destroy!
      group.update!(ci_cd_settings: nil)
    end

    it 'returns false for allowStaleRunnerPruning' do
      request

      expect(group_data).to include('allowStaleRunnerPruning' => eq(false))
    end
  end

  context 'when group has associated ci_cd_settings' do
    before do
      group.ci_cd_settings.update!(allow_stale_runner_pruning: allow_stale_runner_pruning)
    end

    context 'with allow_stale_runner_pruning set to false' do
      let(:allow_stale_runner_pruning) { false }

      it 'returns false for allowStaleRunnerPruning' do
        request

        expect(group_data).to include('allowStaleRunnerPruning' => eq(false))
      end
    end

    context 'with allow_stale_runner_pruning set to true' do
      let(:allow_stale_runner_pruning) { true }

      it 'returns true for allowStaleRunnerPruning' do
        request

        expect(group_data).to include('allowStaleRunnerPruning' => eq(true))
      end
    end
  end
end
