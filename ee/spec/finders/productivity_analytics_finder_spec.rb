# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductivityAnalyticsFinder do
  subject { described_class.new(current_user, search_params.merge(state: :merged)) }

  let_it_be(:project) { create(:project) }

  let(:current_user) { project.first_owner }
  let(:search_params) { {} }

  describe '.array_params' do
    subject { described_class.array_params }

    it { is_expected.to include(:days_to_merge) }
  end

  describe '.scalar_params' do
    subject { described_class.scalar_params }

    it { is_expected.to include(:merged_before, :merged_after) }
  end

  describe '#execute' do
    let(:long_mr) do
      metrics_data = { merged_at: 1.day.ago }
      create(:merge_request, :merged, :with_productivity_metrics, source_project: project, created_at: 31.days.ago, metrics_data: metrics_data)
    end

    let(:short_mr) do
      metrics_data = { merged_at: 28.days.ago }
      create(:merge_request, :merged, :with_productivity_metrics, source_project: project, created_at: 31.days.ago, metrics_data: metrics_data)
    end

    context 'allows to filter by days_to_merge' do
      let(:search_params) { { days_to_merge: [30] } }

      it 'returns all MRs with merged_at - created_at IN specified values', :freeze_time do
        long_mr
        short_mr
        expect(subject.execute).to match_array([long_mr])
      end
    end

    context 'allows to filter by merged_at', :freeze_time do
      let(:pa_start_date) { 2.years.ago }

      before do
        allow(ProductivityAnalytics).to receive(:start_date).and_return(pa_start_date)
      end

      context 'with merged_after specified as timestamp' do
        let(:search_params) do
          {
            merged_after: 25.days.ago.to_s
          }
        end

        it 'returns all MRs with merged date later than specified timestamp' do
          long_mr
          short_mr
          expect(subject.execute).to match_array([long_mr])
        end
      end

      context 'with merged_after and merged_before specified' do
        let(:search_params) do
          {
            merged_after: 30.days.ago.to_s,
            merged_before: 20.days.ago.to_s
          }
        end

        it 'returns all MRs with merged date later than specified timestamp' do
          long_mr
          short_mr
          expect(subject.execute).to match_array([short_mr])
        end
      end

      context 'with merged_after earlier than PA start date' do
        let(:search_params) do
          { merged_after: 3.years.ago.to_s }
        end

        it 'uses start_date as filter value' do
          metrics_data = { merged_at: (2.years + 1.day).ago }
          create(:merge_request, :merged, :with_productivity_metrics, source_project: project, created_at: 800.days.ago, metrics_data: metrics_data)
          long_mr

          expect(subject.execute).to match_array([long_mr])
        end
      end
    end
  end
end
