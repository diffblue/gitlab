# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::AggregateScoresService, feature_category: :value_stream_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:topic1) { create(:topic, name: "topic1") }
  let_it_be(:topic2) { create(:topic, name: "topic2") }
  let_it_be(:project_1) { create(:project, group: group, topics: [topic1]) }
  let_it_be(:project_2) { create(:project, group: group, topics: [topic2]) }
  let_it_be(:project_3) { create(:project, group: group, topics: [topic1, topic2]) }
  let_it_be(:project_4) { create(:project, group: group, name: "Project with no data ever") }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:guest) { create(:user) }

  let(:service) do
    described_class.new(
      container: container,
      current_user: current_user,
      params: params)
  end

  let(:container) { group }
  let(:current_user) { maintainer }
  let(:params) { {} }

  around do |example|
    freeze_time do
      example.run
    end
  end

  before_all do
    group.add_maintainer(maintainer)
    group.add_guest(guest)
  end

  before do
    stub_licensed_features(dora4_analytics: true)
  end

  describe '#execute' do
    subject { service.execute }

    shared_examples_for 'request failure' do
      it 'returns error' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to eq(message)
      end
    end

    context 'when guest user' do
      let(:current_user) { guest }

      it_behaves_like 'request failure' do
        let(:message) { 'You do not have permission to access DORA4 metrics.' }
      end
    end

    context 'when container is nil' do
      let(:container) { nil }
      let(:current_user) { nil }

      it_behaves_like 'request failure' do
        let(:message) { 'Container must be a group.' }
      end
    end

    context 'when there is no data for the target month' do
      it 'returns empty data' do
        expect(subject[:status]).to eq(:success)
        expect(subject.payload[:aggregations]).to match_array([
          counts_by_metric(:lead_time_for_changes, low: nil, med: nil, high: nil, no_data: 4),
          counts_by_metric(:deployment_frequency, low: nil, med: nil, high: nil, no_data: 4),
          counts_by_metric(:change_failure_rate, low: nil, med: nil, high: nil, no_data: 4),
          counts_by_metric(:time_to_restore_service, low: nil, med: nil, high: nil, no_data: 4)
        ])
      end
    end

    context 'when there is data for the target month' do
      let_it_be(:beginning_of_last_month) { Time.current.last_month.beginning_of_month }

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

      let_it_be(:project_3_scores_from_wrong_month) do
        create(:dora_performance_score, project: project_3, date: (beginning_of_last_month - 2.months),
          deployment_frequency: 'low', lead_time_for_changes: 'medium', time_to_restore_service: 'high',
          change_failure_rate: 'high')
      end

      let_it_be(:some_other_groups_scores) do
        create(:dora_performance_score, project: create(:project), date: beginning_of_last_month,
          deployment_frequency: 'low', lead_time_for_changes: 'medium', time_to_restore_service: 'high',
          change_failure_rate: 'high')
      end

      let_it_be(:project_4_scores) do
        create(:dora_performance_score, project: project_4, date: beginning_of_last_month,
          deployment_frequency: nil, lead_time_for_changes: nil, time_to_restore_service: 'high',
          change_failure_rate: 'high')
      end

      it 'returns the aggregated data' do
        expect(subject[:status]).to eq(:success)
        expect(subject.payload[:aggregations]).to match_array([
          counts_by_metric(:deployment_frequency, low: 2, med: 0, high: 1, no_data: 1),
          counts_by_metric(:lead_time_for_changes, low: 0, med: 2, high: 1, no_data: 1),
          counts_by_metric(:time_to_restore_service, low: 0, med: 1, high: 3, no_data: 0),
          counts_by_metric(:change_failure_rate, low: 1, med: 0, high: 3, no_data: 0)
        ])
      end

      context 'when filtering by topic' do
        context 'when single topic' do
          let(:params) { { topic: topic1.name } }

          it 'returns the aggregated data' do
            expect(subject[:status]).to eq(:success)

            expect(subject.payload[:aggregations]).to match_array([
              counts_by_metric(:deployment_frequency, low: 1, med: 0, high: 1, no_data: 0),
              counts_by_metric(:lead_time_for_changes, low: 0, med: 1, high: 1, no_data: 0),
              counts_by_metric(:time_to_restore_service, low: 0, med: 1, high: 1, no_data: 0),
              counts_by_metric(:change_failure_rate, low: 1, med: 0, high: 1, no_data: 0)
            ])
          end
        end

        context 'when multiple topics' do
          let(:params) { { topic: [topic1, topic2].map(&:name) } }

          it 'returns the aggregated data' do
            expect(subject[:status]).to eq(:success)

            expect(subject.payload[:aggregations]).to match_array([
              counts_by_metric(:deployment_frequency, low: 1, med: 0, high: 0, no_data: 0),
              counts_by_metric(:lead_time_for_changes, low: 0, med: 1, high: 0, no_data: 0),
              counts_by_metric(:time_to_restore_service, low: 0, med: 0, high: 1, no_data: 0),
              counts_by_metric(:change_failure_rate, low: 0, med: 0, high: 1, no_data: 0)
            ])
          end
        end
      end
    end

    context 'when there are no authorized projects available to user' do
      it 'returns all empty data' do
        expect_next_instance_of(GroupProjectsFinder) do |finder|
          expect(finder).to receive(:execute).and_return []
        end

        expect(subject[:status]).to eq(:success)
        expect(subject.payload[:aggregations]).to match_array([
          counts_by_metric(:lead_time_for_changes, low: nil, med: nil, high: nil, no_data: 0),
          counts_by_metric(:deployment_frequency, low: nil, med: nil, high: nil, no_data: 0),
          counts_by_metric(:change_failure_rate, low: nil, med: nil, high: nil, no_data: 0),
          counts_by_metric(:time_to_restore_service, low: nil, med: nil, high: nil, no_data: 0)
        ])
      end
    end
  end

  def counts_by_metric(metric_name, low:, med:, high:, no_data:)
    {
      metric_name: metric_name.to_s,
      low_projects_count: low,
      medium_projects_count: med,
      high_projects_count: high,
      no_data_projects_count: no_data
    }
  end
end
