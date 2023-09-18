# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Reducers::CountPerPeriodReducer do
  def find_issuables(project, query)
    Gitlab::Insights::Finders::IssuableFinder.new(project, nil, query: query).find
  end

  def reduce(issuable_relation, period:, period_limit: 5, period_field: :created_at)
    described_class.reduce(issuable_relation, period: period, period_limit: period_limit, period_field: period_field)
  end

  let(:issuable_relation) { find_issuables(project, query) }
  let(:expected) do
    {
      'January 2019' => 1,
      'February 2019' => 0,
      'March 2019' => 1,
      'April 2019' => 1,
      'May 2019' => 0
    }
  end

  subject { reduce(issuable_relation, period: query[:group_by]) }

  context 'with no issues' do
    around do |example|
      travel_to(Time.utc(2019, 5, 5)) { example.run }
    end

    let(:project) { create(:project, :public) }
    let(:query) do
      {
        issuable_state: 'opened',
        issuable_type: 'issue',
        group_by: 'month',
        period_limit: 5
      }
    end

    let(:expected) do
      {
        'January 2019' => 0,
        'February 2019' => 0,
        'March 2019' => 0,
        'April 2019' => 0,
        'May 2019' => 0
      }
    end

    it 'returns no issuables' do
      expect(reduce(issuable_relation, period: query[:group_by])).to eq(expected)
    end
  end

  context 'with open issues' do
    include_context 'Insights issues reducer context', :opened

    let(:query) do
      {
        issuable_state: 'opened',
        issuable_type: 'issue',
        filter_labels: [label_bug.title],
        group_by: 'month',
        period_limit: 5
      }
    end

    it 'raises an error for an unknown :period option' do
      expect { reduce(issuable_relation, period: 'unknown') }.to raise_error(described_class::InvalidPeriodError, "Invalid value for `period`: `unknown`. Allowed values are #{described_class::VALID_PERIOD}!")
    end

    it 'raises an error for an unknown :period_field option' do
      expect { reduce(issuable_relation, period: 'month', period_limit: 5, period_field: :foo) }.to raise_error(described_class::InvalidPeriodFieldError, "Invalid value for `period_field`: `foo`. Allowed values are #{described_class::VALID_PERIOD_FIELDS[:issue].join(', ')}!")
    end

    it 'raises an error for an unknown :period_limit option' do
      expect { reduce(issuable_relation, period: 'month', period_limit: -1) }.to raise_error(described_class::InvalidPeriodLimitError, "Invalid value for `period_limit`: `-1`. Value must be greater than 0!")
    end

    it 'returns issuables with only the needed fields' do
      expect(subject).to eq(expected)
    end

    it 'avoids N + 1 queries' do
      control_queries = ActiveRecord::QueryRecorder.new { subject }
      create(:labeled_issue, :opened, created_at: Time.utc(2019, 2, 5), labels: [label_bug], project: project)

      expect { reduce(find_issuables(project, query), period: query[:group_by]) }.not_to exceed_query_limit(control_queries)
    end
  end

  context 'with closed issues' do
    include_context 'Insights issues reducer context', :closed

    let(:query) do
      {
        issuable_state: 'closed',
        issuable_type: 'issue',
        filter_labels: [label_bug.title],
        group_by: 'month',
        period_limit: 5
      }
    end

    it 'returns issuables with only the needed fields' do
      expect(reduce(issuable_relation, period: query[:group_by], period_field: :closed_at)).to eq(expected)
    end

    it 'works when string `period_field` is passed' do
      expect(reduce(issuable_relation, period: query[:group_by], period_field: 'closed_at')).to eq(expected)
    end
  end

  context 'with opened merge requests' do
    include_context 'Insights merge requests reducer context', :opened

    let(:query) do
      {
        issuable_state: 'opened',
        issuable_type: 'merge_request',
        filter_labels: [label_bug.title],
        group_by: 'month',
        period_limit: 5
      }
    end

    it 'raises an error for an unknown :period_field option' do
      expect { reduce(issuable_relation, period: 'month', period_limit: 5, period_field: :foo) }.to raise_error(described_class::InvalidPeriodFieldError, "Invalid value for `period_field`: `foo`. Allowed values are #{described_class::VALID_PERIOD_FIELDS[:merge_request].join(', ')}!")
    end

    it 'returns issuables with only the needed fields' do
      expect(reduce(issuable_relation, period: query[:group_by], period_field: :created_at)).to eq(expected)
    end
  end

  context 'with merged merge requests' do
    include_context 'Insights merge requests reducer context', :merged

    # Populate the MR metrics' merged_at, except for issuable3 to reproduce a real use-case where merged_at is null.
    before do
      # We're traveling back in the loop below, so we want to travel back to the current time ater the loop
      current_now = Time.current

      3.times do |i|
        merge_request = public_send("issuable#{i}")
        merge_request_metrics_service = MergeRequestMetricsService.new(merge_request.metrics)
        Event.transaction do
          travel_to(merge_request.created_at)

          merge_event = EventCreateService.new.merge_mr(merge_request, merge_request.author)
          merge_request_metrics_service.merge(merge_event)
        end

        travel_to(current_now)
      end
    end

    let(:query) do
      {
        issuable_state: 'merged',
        issuable_type: 'merge_request',
        filter_labels: [label_bug.title],
        group_by: 'month',
        period_limit: 5
      }
    end

    it 'returns issuables with only the needed fields' do
      expect(reduce(issuable_relation, period: query[:group_by], period_field: :merged_at)).to eq(expected)
    end
  end

  context 'with closed merge requests' do
    include_context 'Insights merge requests reducer context', :closed

    let(:query) do
      {
        issuable_state: 'closed',
        issuable_type: 'merge_request',
        filter_labels: [label_bug.title],
        group_by: 'month',
        period_limit: 5
      }
    end

    it 'returns issuables with only the needed fields' do
      expect(reduce(issuable_relation, period: query[:group_by], period_field: :created_at)).to eq(expected)
    end
  end
end
