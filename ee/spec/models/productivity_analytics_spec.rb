# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductivityAnalytics do
  describe 'metrics data' do
    subject(:analytics) { described_class.new(merge_requests: finder_mrs, sort: custom_sort) }

    let(:project) { create(:project) }
    let(:user) { project.first_owner }

    let(:finder_mrs) { ProductivityAnalyticsFinder.new(user, finder_options).execute }
    let(:finder_options) { { state: 'merged' } }

    let(:custom_sort) { nil }

    let(:label_a) { create(:label, project: project) }
    let(:label_b) { create(:label, project: project) }

    let(:long_mr) do
      metrics_data = {
        merged_at: 1.day.ago,
        first_comment_at: 31.days.ago,
        last_commit_at: 2.days.ago,
        commits_count: 20,
        diff_size: 310,
        modified_paths_size: 15
      }
      create(
        :labeled_merge_request, :merged, :with_productivity_metrics,
        labels: [label_a, label_b],
        source_project: project,
        created_at: 31.days.ago,
        metrics_data: metrics_data
      )
    end

    let(:medium_mr) do
      metrics_data = {
        merged_at: 1.day.ago,
        first_comment_at: 15.days.ago,
        last_commit_at: 2.days.ago,
        commits_count: 5,
        diff_size: 84,
        modified_paths_size: 3
      }

      create(
        :labeled_merge_request, :merged, :with_productivity_metrics,
        source_project: project,
        created_at: 15.days.ago,
        metrics_data: metrics_data
      )
    end

    let(:short_mr) do
      metrics_data = {
        merged_at: 28.days.ago,
        first_comment_at: 30.days.ago,
        last_commit_at: 28.days.ago,
        commits_count: 1,
        diff_size: 14,
        modified_paths_size: 3
      }

      create(
        :labeled_merge_request, :merged, :with_productivity_metrics,
        labels: [label_a, label_b],
        source_project: project,
        created_at: 31.days.ago,
        metrics_data: metrics_data
      )
    end

    let(:short_mr_2) do
      metrics_data = {
        merged_at: 28.days.ago,
        first_comment_at: 31.days.ago,
        last_commit_at: 29.days.ago,
        commits_count: 1,
        diff_size: 5,
        modified_paths_size: 1
      }

      create(
        :labeled_merge_request, :merged, :with_productivity_metrics,
        labels: [label_a, label_b],
        source_project: project,
        created_at: 31.days.ago,
        metrics_data: metrics_data
      )
    end

    let(:expected_mr_data) do
      {
        long_mr: {
          'days_to_merge' => 30,
          'time_to_first_comment' => 0,
          'time_to_last_commit' => 29 * 24,
          'time_to_merge' => 24,
          'commits_count' => 20,
          'loc_per_commit' => 15,
          'files_touched' => 15
        },
        medium_mr: {
          'days_to_merge' => 14,
          'time_to_first_comment' => 0,
          'time_to_last_commit' => 13 * 24,
          'time_to_merge' => 24,
          'commits_count' => 5,
          'loc_per_commit' => 16,
          'files_touched' => 3
        },
        short_mr: {
          'days_to_merge' => 3,
          'time_to_first_comment' => 24,
          'time_to_last_commit' => 2 * 24,
          'time_to_merge' => 0,
          'commits_count' => 1,
          'loc_per_commit' => 14,
          'files_touched' => 3
        },
        short_mr_2: {
          'days_to_merge' => 3,
          'time_to_first_comment' => 0,
          'time_to_last_commit' => 2 * 24,
          'time_to_merge' => 24,
          'commits_count' => 1,
          'loc_per_commit' => 5,
          'files_touched' => 1
        }
      }
    end

    before do
      freeze_time do
        long_mr
        medium_mr
        short_mr
        short_mr_2
      end
    end

    describe '#histogram_data' do
      subject(:histogram_data) { analytics.histogram_data(type: metric) }

      using RSpec::Parameterized::TableSyntax

      where(:metric, :expected_result) do
        'days_to_merge' | { 3 => 2, 14 => 1, 30 => 1 }
        'time_to_first_comment' | { 0 => 3, 24 => 1 }
        'time_to_last_commit' | { 13 * 24 => 1, 29 * 24 => 1, 2 * 24 => 2 }
        'time_to_merge' | { 24 => 3, 0 => 1 }
        'commits_count' | { 1 => 2, 5 => 1, 20 => 1 }
        'loc_per_commit' | { 15 => 1, 16 => 1, 14 => 1, 5 => 1 }
        'files_touched' | { 15 => 1, 3 => 2, 1 => 1 }
        'something_invalid' | nil
      end

      with_them do
        it 'calculates correctly' do
          expect(analytics.histogram_data(type: metric)).to eq(expected_result)
        end
      end

      context 'for multiple labeled mrs' do
        let(:finder_options) { super().merge(label_name: [label_a.title, label_b.title]) }
        let(:metric) { 'days_to_merge' }

        it 'returns aggregated data' do
          expect(analytics.histogram_data(type: 'days_to_merge')).to eq(3 => 2, 30 => 1)
        end
      end
    end

    # Test coverage depends on #histogram_data tests. We want to avoid duplication here, so test only for 1 metric.
    describe '#scatterplot_data' do
      subject(:scatterplot_data) { analytics.scatterplot_data(type: 'days_to_merge') }

      it 'returns metric values for each MR' do
        expect(scatterplot_data).to match(
          short_mr.id => { metric: 3, merged_at: be_like_time(short_mr.merged_at) },
          short_mr_2.id => { metric: 3, merged_at: be_like_time(short_mr_2.merged_at) },
          medium_mr.id => { metric: 14, merged_at: be_like_time(medium_mr.merged_at) },
          long_mr.id => { metric: 30, merged_at: be_like_time(long_mr.merged_at) }
        )
      end

      context 'for multiple labeled mrs' do
        let(:finder_options) { super().merge(label_name: [label_a.title, label_b.title]) }

        it 'properly returns MRs with metrics calculated' do
          expected_data = {
            long_mr.id => { metric: 30, merged_at: be_like_time(long_mr.merged_at) },
            short_mr.id => { metric: 3, merged_at: be_like_time(short_mr.merged_at) },
            short_mr_2.id => { metric: 3, merged_at: be_like_time(short_mr_2.merged_at) }
          }

          expect(scatterplot_data).to match(expected_data)
        end
      end
    end

    describe '#merge_requests_extended' do
      subject(:merge_requests) { analytics.merge_requests_extended }

      it 'returns MRs data with all the metrics calculated' do
        expected_data = {
          long_mr.id => expected_mr_data[:long_mr],
          medium_mr.id => expected_mr_data[:medium_mr],
          short_mr.id => expected_mr_data[:short_mr],
          short_mr_2.id => expected_mr_data[:short_mr_2]
        }

        expected_data.each do |mr_id, expected_attributes|
          expect(merge_requests.detect { |mr| mr.id == mr_id }.attributes).to include(expected_attributes)
        end
      end

      context 'with custom sorting' do
        let(:custom_sort) { 'loc_per_commit_asc' }

        it 'reorders MRs according to custom sorting' do
          expect(merge_requests).to eq [short_mr_2, short_mr, long_mr, medium_mr]
        end

        context 'with unknown sorting' do
          let(:custom_sort) { 'weird_stuff' }

          it 'sorts by id desc' do
            expect(merge_requests).to eq [short_mr_2, short_mr, medium_mr, long_mr]
          end
        end
      end

      context 'for multiple labeled mrs' do
        let(:finder_options) { super().merge(label_name: [label_a.title, label_b.title]) }

        it 'properly returns MRs with metrics calculated' do
          expected_data = {
            long_mr.id => expected_mr_data[:long_mr],
            short_mr.id => expected_mr_data[:short_mr],
            short_mr_2.id => expected_mr_data[:short_mr_2]
          }

          expected_data.each do |mr_id, expected_attributes|
            expect(merge_requests.detect { |mr| mr.id == mr_id }.attributes).to include(expected_attributes)
          end
        end
      end
    end
  end

  describe '.start_date' do
    subject(:start_date) { described_class.start_date }

    let(:application_setting) do
      instance_double('ApplicationSetting', productivity_analytics_start_date: 'mocked-start-date')
    end

    it 'delegates to ApplicationSetting' do
      allow(ApplicationSetting).to receive('current').and_return(application_setting)
      expect(start_date).to eq 'mocked-start-date'
    end
  end
end
