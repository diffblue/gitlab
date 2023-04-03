# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'timebox chart' do |timebox_type|
  let_it_be(:issues) { create_list(:issue, 5, project: project) }

  context 'when license is available' do
    before do
      stub_licensed_features(milestone_charts: true, issue_weights: true, iterations: true)
    end

    it 'returns an error when the number of events exceeds the limit' do
      stub_const('Timebox::EventAggregationService::EVENT_COUNT_LIMIT', 1)

      create(:"resource_#{timebox_type}_event", issue: issues[0], timebox_type => timebox, action: :add,
        created_at: timebox_start_date - 21.days)
      create(:"resource_#{timebox_type}_event", issue: issues[1], timebox_type => timebox, action: :add,
        created_at: timebox_start_date - 20.days)

      expect(response)
        .to be_error
        .and have_attributes(message: 'Burnup chart could not be generated due to too many events',
          payload: { code: :too_many_events })
    end

    context 'when events have the same timestamp for created_at', :aggregate_failures do
      let_it_be(:event1) do
        create(:"resource_#{timebox_type}_event", issue: issues[0], timebox_type => another_timebox, action: :add,
          created_at: timebox_start_date)
      end

      let_it_be(:event2) do
        create(:"resource_#{timebox_type}_event", issue: issues[0], timebox_type => another_timebox, action: :remove,
          created_at: timebox_start_date)
      end

      let_it_be(:event3) do
        create(:"resource_#{timebox_type}_event", issue: issues[0], timebox_type => timebox, action: :add,
          created_at: timebox_start_date)
      end

      subject { described_class.new(timebox, scoped_projects) }

      it 'fetches events ordered by created_at and id' do
        query = subject.send(:resource_events_query)
        result = subject.send(:resource_events)

        expect(query).to include("ORDER BY created_at, id")
        expect(result.pluck("id")).to eq([event1.id, event2.id, event3.id])
      end
    end
  end
end

RSpec.describe Timebox::EventAggregationService, :aggregate_failures, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:timebox_start_date) { Date.today }
  let_it_be(:timebox_end_date) { timebox_start_date + 2.weeks }

  let(:scoped_projects) { group.projects }
  let(:response) { described_class.new(timebox, scoped_projects).execute }

  context 'for milestone charts' do
    let_it_be(:timebox, reload: true) do
      create(:milestone, project: project, start_date: timebox_start_date, due_date: timebox_end_date)
    end

    let_it_be(:another_timebox) { create(:milestone, project: project) }

    let(:timebox_without_dates) { build(:milestone, project: project) }

    it_behaves_like 'timebox chart', 'milestone'
  end

  context 'for iteration charts' do
    let_it_be(:cadence) { create(:iterations_cadence, group: group) }
    let_it_be(:timebox, reload: true) do
      create(:iteration, iterations_cadence: cadence, start_date: timebox_start_date, due_date: timebox_end_date)
    end

    let_it_be(:another_timebox) do
      create(:iteration, iterations_cadence: cadence, start_date: timebox_end_date + 1.day,
        due_date: timebox_end_date + 15.days)
    end

    let(:timebox_without_dates) { build(:iteration, group: group, start_date: nil, due_date: nil) }

    it_behaves_like 'timebox chart', 'iteration'
  end

  context 'for timebox type that is not supported' do
    let(:timebox) { Class.new }

    it 'raises an error' do
      expect { response }.to raise_error(ArgumentError, 'Cannot handle timebox type')
    end
  end
end
