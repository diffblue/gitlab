# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::HistoricalStatistic, feature_category: :vulnerability_management do
  describe 'associations' do
    it { is_expected.to belong_to(:project).required(true) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:letter_grade) }
    it { is_expected.to validate_numericality_of(:total).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:critical).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:high).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:medium).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:low).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:unknown).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:info).is_greater_than_or_equal_to(0) }
    it { is_expected.to define_enum_for(:letter_grade).with_values(%i(a b c d f)) }
  end

  describe '.older_than' do
    let_it_be(:statistic_1) { create(:vulnerability_historical_statistic, date: 99.days.ago) }
    let_it_be(:statistic_2) { create(:vulnerability_historical_statistic, date: 100.days.ago) }
    let_it_be(:statistic_3) { create(:vulnerability_historical_statistic, date: 101.days.ago) }

    subject(:older_than) { described_class.older_than(days: 100) }

    it { is_expected.to match_array([statistic_2, statistic_3]) }
  end

  describe '.between_dates' do
    let_it_be(:start_date) { Date.new(2020, 8, 11) }
    let_it_be(:end_date) { Date.new(2020, 8, 13) }

    let_it_be(:historical_statistic_1) { create(:vulnerability_historical_statistic, date: start_date - 1.day) }
    let_it_be(:historical_statistic_2) { create(:vulnerability_historical_statistic, date: start_date) }
    let_it_be(:historical_statistic_3) { create(:vulnerability_historical_statistic, date: start_date + 1.day) }
    let_it_be(:historical_statistic_4) { create(:vulnerability_historical_statistic, date: end_date) }

    subject { described_class.between_dates(start_date, end_date) }

    it { is_expected.to match_array([historical_statistic_2, historical_statistic_3, historical_statistic_4]) }
    it { is_expected.not_to include(historical_statistic_1) }
  end

  describe '.for_project' do
    let_it_be(:project) { create(:project) }
    let_it_be(:other_project) { create(:project) }
    let_it_be(:historical_statistic_1) { create(:vulnerability_historical_statistic, project: project) }
    let_it_be(:historical_statistic_2) { create(:vulnerability_historical_statistic, project: other_project) }

    subject { described_class.for_project(project) }

    it { is_expected.to match_array([historical_statistic_1]) }
  end

  describe '.grouped_by_date' do
    subject { described_class.grouped_by_date(:asc).count }

    let_it_be(:date_1) { Date.new(2020, 8, 10) }
    let_it_be(:date_2) { Date.new(2020, 8, 11) }

    let_it_be(:historical_statistic_1) { create(:vulnerability_historical_statistic, date: date_1) }
    let_it_be(:historical_statistic_2) { create(:vulnerability_historical_statistic, date: date_1) }
    let_it_be(:historical_statistic_3) { create(:vulnerability_historical_statistic, date: date_2) }

    let(:expected_collection) do
      {
        Date.new(2020, 8, 10) => 2,
        Date.new(2020, 8, 11) => 1
      }
    end

    it { is_expected.to match_array(expected_collection) }
  end

  describe '.aggregated_by_date' do
    let_it_be(:date_1) { Date.new(2020, 8, 10) }
    let_it_be(:date_2) { Date.new(2020, 8, 11) }

    let_it_be(:historical_statistic_1) { create(:vulnerability_historical_statistic, date: date_1, total: 21, info: 1, unknown: 2, low: 3, medium: 4, high: 5, critical: 6) }
    let_it_be(:historical_statistic_2) { create(:vulnerability_historical_statistic, date: date_1, total: 21, info: 1, unknown: 2, low: 3, medium: 4, high: 5, critical: 6) }
    let_it_be(:historical_statistic_3) { create(:vulnerability_historical_statistic, date: date_2, total: 57, info: 7, unknown: 8, low: 9, medium: 10, high: 11, critical: 12) }

    subject { described_class.grouped_by_date(:asc).aggregated_by_date.as_json }

    let(:expected_collection) do
      [
        { 'id' => nil, 'date' => '2020-08-10', 'info' => 2, 'unknown' => 4, 'low' => 6, 'medium' => 8, 'high' => 10, 'critical' => 12, 'total' => 42 },
        { 'id' => nil, 'date' => '2020-08-11', 'info' => 7, 'unknown' => 8, 'low' => 9, 'medium' => 10, 'high' => 11, 'critical' => 12, 'total' => 57 }
      ]
    end

    it { is_expected.to match_array(expected_collection) }
  end
end
