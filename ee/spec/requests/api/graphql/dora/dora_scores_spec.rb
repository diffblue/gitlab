# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.[group](fullPath).doraPerformanceScoreCounts', :freeze_time, feature_category: :dora_metrics do
  include GraphqlHelpers

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:ruby_topic) { create(:topic, name: "ruby") }
  let_it_be(:project_1) { create(:project, group: group, topics: [ruby_topic]) }
  let_it_be(:project_2) { create(:project, group: group) }
  let_it_be(:project_3) { create(:project, group: group) }
  let_it_be(:project_4) { create(:project, group: subgroup) }
  let_it_be(:unrelated_project) { create(:project) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let(:post_query) { post_graphql(query, current_user: current_user) }
  let(:path_prefix) { [:group, :doraPerformanceScoreCounts, :nodes] }
  let(:filter_params) { {} }
  let(:query) do
    graphql_query_for(:group, { fullPath: group.full_path },
      query_graphql_field(:doraPerformanceScoreCounts, filter_params, query_body))
  end

  let(:data) { graphql_data_at(*path_prefix) }
  let(:current_user) { reporter }
  let(:query_body) do
    <<~QUERY
      nodes {
        metricName
        lowProjectsCount
        mediumProjectsCount
        highProjectsCount
        noDataProjectsCount
      }
    QUERY
  end

  before do
    stub_licensed_features(dora4_analytics: true)
    group.add_reporter(reporter)
  end

  context 'when DORA analytics feature is not available' do
    before do
      stub_licensed_features(dora4_analytics: false)

      post_query
    end

    it 'returns nil' do
      expect(data).to be_nil
    end

    it_behaves_like 'a working graphql query'
  end

  context 'when user does not have access' do
    let(:current_user) { other_user }

    before do
      post_query
    end

    it 'returns nil' do
      expect(data).to be_nil
    end

    it_behaves_like 'a working graphql query'
  end

  context 'when there is some error in the service' do
    it 'returns an error' do
      expect_next_instance_of(::Dora::AggregateScoresService) do |service|
        expect(service).to receive(:execute)
        .and_return({
          status: :error,
          message: "oh noes!"
        })
      end

      post_query

      expect(data).to be_nil
      expect(graphql_errors.count).to eq(1)
      expect(graphql_errors.first['message']).to match(/oh noes/)
    end
  end

  context 'when there is no data for the target month' do
    describe 'working query' do
      before do
        post_query
      end

      it_behaves_like 'a working graphql query'

      it 'returns all empty data' do
        expect(data).to match_array([
          {
            "metricName" => "lead_time_for_changes",
            "lowProjectsCount" => nil,
            "mediumProjectsCount" => nil,
            "highProjectsCount" => nil,
            "noDataProjectsCount" => 4
          },
          {
            "metricName" => "deployment_frequency",
            "lowProjectsCount" => nil,
            "mediumProjectsCount" => nil,
            "highProjectsCount" => nil,
            "noDataProjectsCount" => 4
          },
          {
            "metricName" => "change_failure_rate",
            "lowProjectsCount" => nil,
            "mediumProjectsCount" => nil,
            "highProjectsCount" => nil,
            "noDataProjectsCount" => 4
          },
          {
            "metricName" => "time_to_restore_service",
            "lowProjectsCount" => nil,
            "mediumProjectsCount" => nil,
            "highProjectsCount" => nil,
            "noDataProjectsCount" => 4
          }
        ])
      end
    end
  end

  context 'when there is data for the target month' do
    let_it_be(:beginning_of_last_month) { Time.current.last_month.beginning_of_month }

    let_it_be(:project_1_scores_from_wrong_month) do
      create(:dora_performance_score, project: project_1, date: (beginning_of_last_month - 2.months),
        deployment_frequency: 'low', lead_time_for_changes: 'medium', time_to_restore_service: 'high',
        change_failure_rate: 'high')
    end

    let_it_be(:scores_from_some_other_groups_project) do
      create(:dora_performance_score, project: create(:project), date: beginning_of_last_month,
        deployment_frequency: 'low', lead_time_for_changes: 'medium', time_to_restore_service: 'high',
        change_failure_rate: 'high')
    end

    let_it_be(:project_1_scores) do
      create(:dora_performance_score, project: project_1, date: beginning_of_last_month,
        deployment_frequency: 'high', lead_time_for_changes: 'high', time_to_restore_service: 'medium',
        change_failure_rate: 'low')
    end

    let_it_be(:project_2_scores) do
      create(:dora_performance_score, project: project_2, date: beginning_of_last_month,
        deployment_frequency: 'low', lead_time_for_changes: 'medium', time_to_restore_service: 'high',
        change_failure_rate: 'high')
    end

    let_it_be(:project_3_scores) do
      create(:dora_performance_score, project: project_3, date: beginning_of_last_month,
        deployment_frequency: 'low', lead_time_for_changes: 'medium', time_to_restore_service: 'high',
        change_failure_rate: 'high')
    end

    let_it_be(:project_4_scores) do
      create(:dora_performance_score, project: project_4, date: beginning_of_last_month,
        deployment_frequency: nil, lead_time_for_changes: nil, time_to_restore_service: nil,
        change_failure_rate: 'high')
    end

    let_it_be(:scores_for_unrelated_project) do
      # wow, they're doing great! We're not interested in their scores though
      create(:dora_performance_score, project: unrelated_project, date: beginning_of_last_month,
        deployment_frequency: 'high', lead_time_for_changes: 'low', time_to_restore_service: 'low',
        change_failure_rate: 'low')
    end

    describe 'working query' do
      before do
        post_query
      end

      it_behaves_like 'a working graphql query'

      context 'when no filters are applied' do
        let(:filter_params) { {} }

        it 'returns the correct data' do
          expect(data).to match_array([
            {
              'metricName' => "lead_time_for_changes",
              'lowProjectsCount' => 0,
              'mediumProjectsCount' => 2,
              'highProjectsCount' => 1,
              "noDataProjectsCount" => 1
            },
            {
              'metricName' => "deployment_frequency",
              'lowProjectsCount' => 2,
              'mediumProjectsCount' => 0,
              'highProjectsCount' => 1,
              "noDataProjectsCount" => 1
            },
            {
              'metricName' => "change_failure_rate",
              'lowProjectsCount' => 1,
              'mediumProjectsCount' => 0,
              'highProjectsCount' => 3,
              "noDataProjectsCount" => 0
            },
            {
              'metricName' => "time_to_restore_service",
              'lowProjectsCount' => 0,
              'mediumProjectsCount' => 1,
              'highProjectsCount' => 2,
              "noDataProjectsCount" => 1
            }
          ])
        end
      end

      context 'when filters are applied' do
        let(:filter_params) { { projectFilters: { topic: [ruby_topic.name] } } }

        it 'returns the correct data' do
          expect(data).to match_array([
            {
              'metricName' => "lead_time_for_changes",
              'lowProjectsCount' => 0,
              'mediumProjectsCount' => 0,
              'highProjectsCount' => 1,
              "noDataProjectsCount" => 0
            },
            {
              'metricName' => "deployment_frequency",
              'lowProjectsCount' => 0,
              'mediumProjectsCount' => 0,
              'highProjectsCount' => 1,
              "noDataProjectsCount" => 0
            },
            {
              'metricName' => "change_failure_rate",
              'lowProjectsCount' => 1,
              'mediumProjectsCount' => 0,
              'highProjectsCount' => 0,
              "noDataProjectsCount" => 0
            },
            {
              'metricName' => "time_to_restore_service",
              'lowProjectsCount' => 0,
              'mediumProjectsCount' => 1,
              'highProjectsCount' => 0,
              "noDataProjectsCount" => 0
            }
          ])
        end
      end

      context 'when no metric count fields are requested' do
        let(:query_body) do
          <<~QUERY
            nodes {
              metricName
            }
          QUERY
        end

        it 'does not fire off any data queries' do
          expect(Dora::AggregateScoresService).not_to receive(:execute)

          post_query
        end

        it_behaves_like 'a working graphql query'
      end
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
