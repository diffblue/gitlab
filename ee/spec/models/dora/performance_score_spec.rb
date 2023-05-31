# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::PerformanceScore, type: :model, feature_category: :value_stream_management do
  subject { build :dora_performance_score }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to validate_presence_of(:project) }
  it { is_expected.to validate_presence_of(:date) }
  it { is_expected.to validate_uniqueness_of(:date).scoped_to(:project_id) }

  describe '.refresh!' do
    let_it_be(:project) { create :project }
    let(:date) { Date.today }
    let(:calculated_scores) do
      { 'deployment_frequency' => 'low',
        'lead_time_for_changes' => 'medium',
        'time_to_restore_service' => 'high',
        'change_failure_rate' => nil }
    end

    before do
      allow(Analytics::DoraPerformanceScoreCalculator)
        .to receive(:scores_for).with(project, date.beginning_of_month).and_return(calculated_scores)
    end

    it 'creates new record with calculated scores' do
      described_class.refresh!(project, date)

      expect(described_class.find_by(project: project,
        date: date.beginning_of_month)).to have_attributes(calculated_scores)
    end

    context 'when record already exists' do
      let!(:existing_record) { create :dora_performance_score, project: project, date: date.beginning_of_month }

      it 'updates existing one' do
        expect do
          described_class.refresh!(project, date)
        end.not_to change { described_class.count }

        expect(existing_record.reload).to have_attributes(calculated_scores)
      end
    end
  end

  describe 'scopes', :freeze_time do
    let_it_be(:group) { create(:group) }
    let_it_be(:project1) { create(:project, group: group) }
    let_it_be(:project2) { create(:project, group: group) }
    let_it_be(:project3) { create(:project, group: group) }

    let_it_be(:beginning_of_last_month) { Time.current.last_month.beginning_of_month }

    let_it_be(:project1_scores_from_other_month) do
      create(:dora_performance_score, project: project1, date: (beginning_of_last_month - 2.months),
        deployment_frequency: 'low', lead_time_for_changes: 'medium', time_to_restore_service: 'high',
        change_failure_rate: 'high')
    end

    let_it_be(:project1_scores) do
      create(:dora_performance_score, project: project1, date: beginning_of_last_month,
        deployment_frequency: 'high', lead_time_for_changes: 'high', time_to_restore_service: 'medium',
        change_failure_rate: 'low')
    end

    let_it_be(:project2_scores_from_other_month) do
      create(:dora_performance_score, project: project2, date: (beginning_of_last_month - 3.months),
        deployment_frequency: 'low', lead_time_for_changes: 'medium', time_to_restore_service: 'high',
        change_failure_rate: 'high')
    end

    let_it_be(:project2_scores) do
      create(:dora_performance_score, project: project2, date: beginning_of_last_month,
        deployment_frequency: 'low', lead_time_for_changes: 'medium', time_to_restore_service: 'high',
        change_failure_rate: 'high')
    end

    let_it_be(:project3_scores) do
      create(:dora_performance_score, project: project3, date: beginning_of_last_month,
        deployment_frequency: 'low', lead_time_for_changes: nil, time_to_restore_service: 'high',
        change_failure_rate: 'high')
    end

    describe '.for_projects' do
      it 'includes only the given projects' do
        expect(described_class.for_projects([project1, project2]))
          .to match_array([
            project1_scores,
            project2_scores,
            project1_scores_from_other_month,
            project2_scores_from_other_month
          ])
      end
    end

    describe '.for_dates' do
      context 'when given a single date' do
        it 'includes only the scores from that given date' do
          expect(described_class.for_dates(beginning_of_last_month))
            .to match_array([project1_scores, project2_scores, project3_scores])
        end
      end

      context 'when given a date range' do
        it 'includes only the scores from that given date' do
          from_date = beginning_of_last_month - 10.weeks
          to_date = beginning_of_last_month + 1.week

          expect(described_class.for_dates(from_date..to_date))
            .to match_array([
              project1_scores,
              project1_scores_from_other_month,
              project2_scores,
              project3_scores
            ])
        end
      end
    end

    describe '.group_counts_by_metric' do
      context 'when given a valid metric' do
        it 'groups the metrics' do
          expect(described_class.group_counts_by_metric(:lead_time_for_changes))
            .to match_array([["high", 1], ["medium", 3], [nil, 1]])
        end
      end
    end

    describe 'combining scopes' do
      it 'filters properly' do
        expect(described_class.for_dates(beginning_of_last_month).for_projects(project1))
          .to match_array([project1_scores])
      end
    end
  end
end
