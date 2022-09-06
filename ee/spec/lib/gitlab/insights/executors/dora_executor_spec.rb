# frozen_string_literal:  true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Executors::DoraExecutor do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user).tap { |u| group.add_developer(u) } }
  let_it_be(:project1) { create(:project, group: group) }
  let_it_be(:project2) { create(:project, group: group) }

  let_it_be(:environment1) { create(:environment, :production, project: project1) }
  let_it_be(:environment2) { create(:environment, :production, project: project2) }
  let_it_be(:environment3) { create(:environment, :staging, project: project2) }

  let(:query_params) do
    {
      metric: 'deployment_frequency',
      group_by: 'month',
      period_limit: 5
    }
  end

  let(:projects) { {} }
  let(:chart_type) { 'bar' }

  subject(:serialized_data) do
    described_class.new(
      query_params: query_params,
      current_user: user,
      insights_entity: insights_entity,
      projects: projects,
      chart_type: chart_type
    ).execute
  end

  before do
    stub_licensed_features(dora4_analytics: true)
  end

  before(:all) do
    date1 = Date.today
    date2 = date1 - 3.months

    create(:dora_daily_metrics,
           deployment_frequency: 5,
           lead_time_for_changes_in_seconds: 100,
           environment: environment1,
           date: date1)

    create(:dora_daily_metrics,
           deployment_frequency: 20,
           lead_time_for_changes_in_seconds: 10000,
           incidents_count: 5,
           environment: environment2,
           date: date1)

    create(:dora_daily_metrics,
           deployment_frequency: 50,
           lead_time_for_changes_in_seconds: 20000,
           incidents_count: 15,
           environment: environment1,
           date: date2)

    create(:dora_daily_metrics,
           deployment_frequency: 100,
           lead_time_for_changes_in_seconds: 40000,
           environment: environment3,
           date: date2)
  end

  shared_examples 'serialized_data examples' do
    it 'returns correctly aggregated data' do
      expect(serialized_data['datasets'].first['data']).to eq(expected_result)
    end
  end

  context 'when Dora::AggregateMetricsService fails' do
    let(:insights_entity) { group }

    before do
      stub_licensed_features(dora4_analytics: false)
    end

    it 'raises an error' do
      expect { serialized_data }.to raise_error(described_class::DoraExecutorError)
    end
  end

  context 'when executing for a group' do
    let(:insights_entity) { group }

    it_behaves_like 'serialized_data examples' do
      let(:expected_result) { [0, 50, 0, 0, 25] }
    end

    context 'when requesting the lead_time_for_changes metric' do
      before do
        query_params[:metric] = 'lead_time_for_changes'
      end

      it_behaves_like 'serialized_data examples' do
        let(:expected_result) { [nil, 0.2, nil, nil, 0.1] }
      end
    end

    context 'when requesting the change_failure_rate metric' do
      before do
        query_params[:metric] = 'change_failure_rate'
      end

      it_behaves_like 'serialized_data examples' do
        let(:expected_result) { [nil, 30, nil, nil, 20] }
      end
    end

    context 'when filtering environment tiers' do
      before do
        query_params[:environment_tiers] = %w[staging production]
      end

      it_behaves_like 'serialized_data examples' do
        let(:expected_result) { [0, 150, 0, 0, 25] }
      end
    end

    context 'when filtering projects' do
      context 'when filtering by id' do
        let(:projects) { { only: [project2.id] } }

        it_behaves_like 'serialized_data examples' do
          let(:expected_result) { [0, 0, 0, 0, 20] }
        end
      end

      context 'when filtering by full path' do
        let(:projects) { { only: [project2.full_path] } }

        it_behaves_like 'serialized_data examples' do
          let(:expected_result) { [0, 0, 0, 0, 20] }
        end
      end
    end

    context 'when unknown group_by is given' do
      before do
        query_params[:group_by] = 'unknown'
      end

      it 'raises error' do
        expect do
          serialized_data
        end.to raise_error /Unknown group_by value is given/
      end
    end

    context 'when unknown chart type is given' do
      let(:chart_type) { 'stacked-bar' }

      it 'raises error' do
        expect do
          serialized_data
        end.to raise_error /Unsupported chart type is given/
      end
    end
  end

  context 'when executing for a project' do
    let(:insights_entity) { project1 }

    it_behaves_like 'serialized_data examples' do
      let(:expected_result) { [0, 50, 0, 0, 5] }
    end

    context 'when filtering projects' do
      context 'when filtering by id' do
        let(:projects) { { only: [project1.id] } }

        it_behaves_like 'serialized_data examples' do
          let(:expected_result) { [0, 50, 0, 0, 5] }
        end
      end

      context 'when filtering out the current project' do
        let(:projects) { { only: [project2.full_path] } }

        # ignores the filter
        it_behaves_like 'serialized_data examples' do
          let(:expected_result) { [0, 50, 0, 0, 5] }
        end
      end
    end
  end
end
