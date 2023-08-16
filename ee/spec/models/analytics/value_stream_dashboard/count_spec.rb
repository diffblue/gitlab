# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::ValueStreamDashboard::Count, feature_category: :value_stream_management do
  subject(:model) { build(:value_stream_dashboard_count) }

  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace_id) }
    it { is_expected.to validate_presence_of(:recorded_at) }
    it { is_expected.to validate_presence_of(:count) }
  end

  describe '.latest_first_order' do
    it 'returns the results in a correct order' do
      timestamp1 = 2.months.ago
      timestamp2 = 3.months.ago

      count1 = create(:value_stream_dashboard_count, recorded_at: timestamp2)
      count2 = create(:value_stream_dashboard_count, recorded_at: timestamp1)
      count3 = create(:value_stream_dashboard_count, recorded_at: timestamp2)

      expect(described_class.latest_first_order).to eq([count2, count3, count1])
    end
  end

  describe '.aggregate_for_period' do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:subsubgroup) { create(:group, parent: subgroup) }

    let_it_be(:project1) { create(:project, group: subgroup) }
    let_it_be(:project2) { create(:project, group: subsubgroup) }

    let_it_be(:issue_aggregation1) do
      create(:value_stream_dashboard_count, metric: :issues, count: 2, namespace: project1.project_namespace,
        recorded_at: '2023-05-25')
    end

    let_it_be(:issue_aggregation2) do
      create(:value_stream_dashboard_count, metric: :issues, count: 1, namespace: project2.project_namespace,
        recorded_at: '2023-05-26')
    end

    # Should not be calculated in the results
    let_it_be(:issue_aggregation_past) do
      create(:value_stream_dashboard_count, metric: :issues, count: 1, namespace: project2.project_namespace,
        recorded_at: '2023-04-25')
    end

    let_it_be(:group_aggregation) do
      create(:value_stream_dashboard_count, metric: :groups, count: 1, namespace: group, recorded_at: '2023-05-25')
    end

    let_it_be(:group_aggregation_subgroup) do
      create(:value_stream_dashboard_count, metric: :groups, count: 1, namespace: subgroup, recorded_at: '2023-05-25')
    end

    let(:group_to_aggregate) { group }
    let(:from) { Date.new(2023, 5, 1) }
    let(:to) { Date.new(2023, 5, 31) }

    let(:result) { described_class.aggregate_for_period(group_to_aggregate, metric, from, to) }
    let(:last_recorded_at) { result&.last }

    subject(:count) { result&.first }

    context 'when requesting issue counts' do
      let(:metric) { :issues }

      it 'correctly counts the issues in the given time frame' do
        expect(count).to eq(3)
      end

      context 'when there are more measurements within the given time frame' do
        before do
          create(:value_stream_dashboard_count, metric: :groups, count: 100, namespace: group,
            recorded_at: '2023-05-10')
        end

        it 'takes the latest measurements' do
          expect(count).to eq(3)
        end
      end

      context 'when querying a subgroup' do
        let(:group_to_aggregate) { subsubgroup }

        it 'returns count scoped to the subgroup' do
          expect(count).to eq(1)
        end
      end
    end

    context 'when requesting group counts' do
      let(:metric) { :groups }

      it 'correctly counts the groups in the given time frame' do
        expect(count).to eq(2)
      end

      context 'when querying a subgroup' do
        let(:group_to_aggregate) { subgroup }

        it 'returns count scoped to the subgroup' do
          expect(count).to eq(1)
        end
      end

      context 'when querying group without data' do
        let(:group_to_aggregate) { subsubgroup }

        it 'returns nil count' do
          expect(count).to eq(nil)
        end
      end

      context 'when querying group in a date range where data is not available' do
        let(:from) { Date.new(2023, 1, 1) }
        let(:to) { Date.new(2023, 1, 31) }

        it 'returns nil count' do
          expect(count).to eq(nil)
        end
      end

      context 'when unsupported namespace class is passed' do
        it 'returns 0 count' do
          stub_const('Analytics::ValueStreamDashboard::TopLevelGroupCounterService::COUNTS_TO_COLLECT',
            { groups: { namespace_class: Namespace } })

          expect(count).to eq(nil)
        end
      end
    end
  end
end
