# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuablesAnalytics do
  describe '#data' do
    let(:project) { create(:project, :empty_repo) }

    # The hash key is the number of months back that the issue `created_at` will be.
    # The hash value is the number of issues created for the month key.
    let(:seed) do
      { 0 => 2, 1 => 0, 2 => 1, 3 => 2, 4 => 1, 5 => 1, 6 => 1, 7 => 1, 8 => 1, 9 => 2, 10 => 1, 11 => 0 }
    end

    before do
      travel_to(Time.current) do
        seed.each_pair do |months_back, issues_count|
          create_list(:issue, issues_count, project: project, created_at: months_back.months.ago)
        end
      end
    end

    context 'when issuable relation is ordered by priority' do
      it 'generates chart data correctly' do
        issues = project.issues.order_labels_priority
        data = described_class.new(issuables: issues).data

        seed.each_pair do |months_back, issues_count|
          date = months_back.months.ago.strftime(described_class::DATE_FORMAT)
          expect(data[date]).to eq(issues_count)
        end
      end
    end

    context 'when months_back parameter is nil' do
      it 'returns a hash containing the issues count created in the past 12 months' do
        data = described_class.new(issuables: project.issues).data

        seed.each_pair do |months_back, issues_count|
          date = months_back.months.ago.strftime(described_class::DATE_FORMAT)
          expect(data[date]).to eq(issues_count)
        end
      end
    end

    context 'when months_back parameter is present' do
      it 'returns a hash containing the issues count created in the past x months' do
        data = described_class.new(issuables: project.issues, months_back: 3).data

        filtered_seed = seed.keep_if do |months_back, _|
          months_back < 3
        end

        filtered_seed.each_pair do |months_back, issues_count|
          date = months_back.months.ago.strftime(described_class::DATE_FORMAT)
          expect(data[date]).to eq(issues_count)
        end
      end
    end
  end
end
