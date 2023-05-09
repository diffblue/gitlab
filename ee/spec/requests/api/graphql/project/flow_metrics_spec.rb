# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project flow metrics', feature_category: :value_stream_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project1) { create(:project, :repository, group: group) }
  # This is done so we can use the same count expectations in the shared examples and
  # reuse the shared example for the group-level test.
  let_it_be(:project2) { project1 }
  let_it_be(:production_environment1) { create(:environment, :production, project: project1) }
  let_it_be(:production_environment2) { production_environment1 }
  let_it_be(:current_user) { create(:user, maintainer_projects: [project1]) }

  let(:full_path) { project1.full_path }
  let(:context) { :project }

  before do
    # cycle_analytics_for_groups is needed for the aggregations
    stub_licensed_features(cycle_analytics_for_groups: true, cycle_analytics_for_projects: true)
  end

  it_behaves_like 'value stream analytics flow metrics deploymentCount examples' do
    let(:deployments) { [deployment1, deployment2, deployment3] }

    before do
      deployments.each do |deployment|
        Dora::DailyMetrics.refresh!(deployment.environment, deployment.finished_at.to_date)
      end
    end

    it 'uses DORA data' do
      expect(Dora::DailyMetrics).to receive(:for_environments).and_call_original

      result
    end
  end

  it_behaves_like 'value stream analytics flow metrics leadTime examples' do
    context 'when cycle analytics is not licensed' do
      before do
        stub_licensed_features(cycle_analytics_for_projects: false)
      end

      it 'returns nil' do
        expect(result).to eq(nil)
      end
    end
  end

  it_behaves_like 'value stream analytics flow metrics cycleTime examples' do
    context 'when cycle analytics is not licensed' do
      before do
        stub_licensed_features(cycle_analytics_for_projects: false)
      end

      it 'returns nil' do
        expect(result).to eq(nil)
      end
    end
  end

  it_behaves_like 'value stream analytics flow metrics issuesCompleted examples' do
    context 'when cycle analytics is not licensed' do
      before do
        stub_licensed_features(cycle_analytics_for_projects: false)
      end

      it 'returns nil' do
        expect(result).to eq(nil)
      end
    end
  end
end
