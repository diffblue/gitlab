# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'timebox chart' do |timebox_type|
  let_it_be(:issues) { create_list(:issue, 5, project: project) }

  context 'when license is not available' do
    before do
      stub_licensed_features(milestone_charts: false, iterations: false)
    end

    it 'returns an error message' do
      expect(response)
        .to be_error
        .and have_attributes(message: eq("#{timebox_type.capitalize} does not support burnup charts"), payload: { code: :unsupported_type })
    end
  end

  context 'when license is available' do
    before do
      stub_licensed_features(milestone_charts: true, issue_weights: true, iterations: true)
    end

    context 'when milestone does not have a start and due date' do
      let(:timebox) { timebox_without_dates }

      it 'returns an error message' do
        expect(response)
          .to be_error
          .and have_attributes(message: eq("#{timebox_type.capitalize} must have a start and due date"), payload: { code: :missing_dates })
      end
    end

    it 'returns an error when the number of events exceeds the limit' do
      stub_const('TimeboxReportService::EVENT_COUNT_LIMIT', 1)

      create(:"resource_#{timebox_type}_event", issue: issues[0], timebox_type => timebox, action: :add, created_at: timebox_start_date - 21.days)
      create(:"resource_#{timebox_type}_event", issue: issues[1], timebox_type => timebox, action: :add, created_at: timebox_start_date - 20.days)

      expect(response)
        .to be_error
        .and have_attributes(message: 'Burnup chart could not be generated due to too many events', payload: { code: :too_many_events })
    end

    it 'aggregates events before the start date to the start date' do
      create(:"resource_#{timebox_type}_event", issue: issues[0], timebox_type => timebox, action: :add, created_at: timebox_start_date - 21.days)
      create(:resource_weight_event, issue: issues[0], weight: 2, created_at: timebox_start_date - 14.days)

      create(:"resource_#{timebox_type}_event", issue: issues[1], timebox_type => timebox, action: :add, created_at: timebox_start_date - 20.days)
      create(:resource_weight_event, issue: issues[1], weight: 1, created_at: timebox_start_date - 14.days)

      create(:"resource_#{timebox_type}_event", issue: issues[2], timebox_type => timebox, action: :add, created_at: timebox_start_date - 20.days)
      create(:resource_weight_event, issue: issues[2], weight: 3, created_at: timebox_start_date - 14.days)
      create(:resource_state_event, issue: issues[2], state: :closed, created_at: timebox_start_date - 7.days)

      create(:"resource_#{timebox_type}_event", issue: issues[3], timebox_type => timebox, action: :add, created_at: timebox_start_date - 19.days)
      create(:resource_weight_event, issue: issues[3], weight: 4, created_at: timebox_start_date - 14.days)
      create(:resource_state_event, issue: issues[3], state: :closed, created_at: timebox_start_date - 6.days)

      expect(response.success?).to eq(true)
      expect(response.payload[:stats]).to eq({
        complete: { count: 2, weight: 7 },
        incomplete: { count: 2, weight: 3 },
        total: { count: 4, weight: 10 }
      })

      expect(response.payload[:burnup_time_series]).to eq(
        [
          {
            date: timebox_start_date,
            scope_count: 4,
            scope_weight: 10,
            completed_count: 2,
            completed_weight: 7
          }
        ])
    end

    context 'when events have the same timestamp for created_at', :aggregate_failures do
      let_it_be(:event1) { create(:"resource_#{timebox_type}_event", issue: issues[0], timebox_type => another_timebox, action: :add, created_at: timebox_start_date) }
      let_it_be(:event2) { create(:"resource_#{timebox_type}_event", issue: issues[0], timebox_type => another_timebox, action: :remove, created_at: timebox_start_date) }
      let_it_be(:event3) { create(:"resource_#{timebox_type}_event", issue: issues[0], timebox_type => timebox, action: :add, created_at: timebox_start_date) }

      subject { described_class.new(timebox, scoped_projects) }

      it 'fetches events ordered by created_at and id' do
        query = subject.send(:resource_events_query)
        result = subject.send(:resource_events)

        expect(query).to include("ORDER BY created_at, id")
        expect(result.pluck("id")).to eq([event1.id, event2.id, event3.id])
      end

      it 'handles events for the same issue with exactly the same timestamp' do
        expect(response.success?).to eq(true)
        expect(response.payload[:stats]).to eq({
          complete: { count: 0, weight: 0 },
          incomplete: { count: 1, weight: 0 },
          total: { count: 1, weight: 0 }
        })

        expect(response.payload[:burnup_time_series]).to eq(
          [
            {
              date: timebox_start_date,
              scope_count: 1,
              scope_weight: 0,
              completed_count: 0,
              completed_weight: 0
            }
          ])
      end
    end

    it 'updates counts and weight when the milestone is added or removed' do
      # Add milestone to an open issue with no weight.
      create(:"resource_#{timebox_type}_event", issue: issues[0], timebox_type => timebox, action: :add, created_at: timebox_start_date + 4.days + 3.hours)
      # Ignore duplicate add event.
      create(:"resource_#{timebox_type}_event", issue: issues[0], timebox_type => timebox, action: :add, created_at: timebox_start_date + 4.days + 3.hours)

      # Add milestone to an open issue with weight 2 on the same day. This should increment the scope totals for the same day.
      create(:resource_weight_event, issue: issues[1], weight: 2, created_at: timebox_start_date)
      create(:"resource_#{timebox_type}_event", issue: issues[1], timebox_type => timebox, action: :add, created_at: timebox_start_date + 4.days + 5.hours)

      # Add milestone to already closed issue with weight 3. This should increment both the scope and completed totals.
      create(:resource_weight_event, issue: issues[2], weight: 3, created_at: timebox_start_date)
      create(:resource_state_event, issue: issues[2], state: :closed, created_at: timebox_start_date + 4.days)
      create(:"resource_#{timebox_type}_event", issue: issues[2], timebox_type => timebox, action: :add, created_at: timebox_start_date + 5.days)

      # Remove milestone from the 2nd open issue. This should decrement the scope totals.
      create(:"resource_#{timebox_type}_event", issue: issues[1], timebox_type => timebox, action: :remove, created_at: timebox_start_date + 6.days)

      # Remove milestone from the closed issue. This should decrement both the scope and completed totals.
      create(:"resource_#{timebox_type}_event", issue: issues[2], timebox_type => timebox, action: :remove, created_at: timebox_start_date + 7.days)

      # Adding a different milestone should not affect the data.
      create(:"resource_#{timebox_type}_event", issue: issues[3], timebox_type => another_timebox, action: :add, created_at: timebox_start_date + 7.days)

      # Adding the milestone after the due date should not affect the data.
      create(:"resource_#{timebox_type}_event", issue: issues[4], timebox_type => timebox, action: :add, created_at: timebox_start_date + 21.days)

      # Removing the milestone after the due date should not affect the data.
      create(:"resource_#{timebox_type}_event", issue: issues[0], timebox_type => timebox, action: :remove, created_at: timebox_start_date + 21.days)

      expect(response.success?).to eq(true)
      expect(response.payload[:stats]).to eq({
        complete: { count: 0, weight: 0 },
        incomplete: { count: 1, weight: 0 },
        total: { count: 1, weight: 0 }
      })
      expect(response.payload[:burnup_time_series]).to eq(
        [
          {
             date: timebox_start_date + 4.days,
             scope_count: 2,
             scope_weight: 2,
             completed_count: 0,
             completed_weight: 0
           },
          {
            date: timebox_start_date + 5.days,
            scope_count: 3,
            scope_weight: 5,
            completed_count: 1,
            completed_weight: 3
          },
          {
            date: timebox_start_date + 6.days,
            scope_count: 2,
            scope_weight: 3,
            completed_count: 1,
            completed_weight: 3
          },
          {
            date: timebox_start_date + 7.days,
            scope_count: 1,
            scope_weight: 0,
            completed_count: 0,
            completed_weight: 0
          }
        ])
    end

    it 'updates the completed counts when issue state is changed' do
      # Close an issue assigned to the milestone with weight 2. This should increment the completed totals.
      create(:"resource_#{timebox_type}_event", issue: issues[0], timebox_type => timebox, action: :add, created_at: timebox_start_date + 1.hour)
      create(:resource_weight_event, issue: issues[0], weight: 2, created_at: timebox_start_date + 2.hours)
      create(:resource_state_event, issue: issues[0], state: :closed, created_at: timebox_start_date + 1.day)

      # Closing an issue that is already closed should be ignored.
      create(:resource_state_event, issue: issues[0], state: :closed, created_at: timebox_start_date + 2.days)

      # Re-opening the issue should decrement the completed totals.
      create(:resource_state_event, issue: issues[0], state: :reopened, created_at: timebox_start_date + 3.days)

      # Closing and re-opening an issue on the same day should not change the totals.
      create(:"resource_#{timebox_type}_event", issue: issues[1], timebox_type => timebox, action: :add, created_at: timebox_start_date + 4.days + 1.hour)
      create(:resource_weight_event, issue: issues[1], weight: 3, created_at: timebox_start_date + 4.days + 2.hours)
      create(:resource_state_event, issue: issues[1], state: :closed, created_at: timebox_start_date + 5.days + 5.hours)
      create(:resource_state_event, issue: issues[1], state: :reopened, created_at: timebox_start_date + 5.days + 8.hours)

      # Re-opening an issue that is already open should be ignored.
      create(:resource_state_event, issue: issues[1], state: :reopened, created_at: timebox_start_date + 6.days)

      # Closing a re-opened issue should increment the completed totals.
      create(:resource_state_event, issue: issues[1], state: :closed, created_at: timebox_start_date + 7.days)

      # Changing state when the milestone is already removed should not affect the data.
      create(:"resource_#{timebox_type}_event", issue: issues[1], action: :remove, created_at: timebox_start_date + 8.days)
      create(:resource_state_event, issue: issues[1], state: :closed, created_at: timebox_start_date + 9.days)

      expect(response.success?).to eq(true)
      expect(response.payload[:stats]).to eq({
        complete: { count: 0, weight: 0 },
        incomplete: { count: 1, weight: 2 },
        total: { count: 1, weight: 2 }
      })
      expect(response.payload[:burnup_time_series]).to eq(
        [
          {
            date: timebox_start_date,
            scope_count: 1,
            scope_weight: 2,
            completed_count: 0,
            completed_weight: 0
          },
          {
            date: timebox_start_date + 1.day,
            scope_count: 1,
            scope_weight: 2,
            completed_count: 1,
            completed_weight: 2
          },
          {
            date: timebox_start_date + 3.days,
            scope_count: 1,
            scope_weight: 2,
            completed_count: 0,
            completed_weight: 0
          },
          {
            date: timebox_start_date + 4.days,
            scope_count: 2,
            scope_weight: 5,
            completed_count: 0,
            completed_weight: 0
          },
          {
            date: timebox_start_date + 5.days,
            scope_count: 2,
            scope_weight: 5,
            completed_count: 0,
            completed_weight: 0
          },
          {
            date: timebox_start_date + 7.days,
            scope_count: 2,
            scope_weight: 5,
            completed_count: 1,
            completed_weight: 3
          },
          {
            date: timebox_start_date + 8.days,
            scope_count: 1,
            scope_weight: 2,
            completed_count: 0,
            completed_weight: 0
          }
        ])
    end

    it 'updates the weight totals when issue weight is changed' do
      # Issue starts out with no weight and should increment once the weight is changed to 2.
      create(:"resource_#{timebox_type}_event", issue: issues[0], timebox_type => timebox, action: :add, created_at: timebox_start_date)
      create(:resource_weight_event, issue: issues[0], weight: 2, created_at: timebox_start_date + 1.day)

      # A closed issue is added and weight is set to 5 and should add to the weight totals.
      create(:"resource_#{timebox_type}_event", issue: issues[1], timebox_type => timebox, action: :add, created_at: timebox_start_date + 2.days + 1.hour)
      create(:resource_state_event, issue: issues[1], state: :closed, created_at: timebox_start_date + 2.days + 2.hours)
      create(:resource_weight_event, issue: issues[1], weight: 5, created_at: timebox_start_date + 2.days + 3.hours)

      # Lowering the weight of the 2nd issue should decrement the weight totals.
      create(:resource_weight_event, issue: issues[1], weight: 1, created_at: timebox_start_date + 3.days)

      # After the first issue is assigned to another milestone, weight changes shouldn't affect the data.
      create(:"resource_#{timebox_type}_event", issue: issues[0], timebox_type => another_timebox, action: :add, created_at: timebox_start_date + 4.days)
      create(:resource_weight_event, issue: issues[0], weight: 10, created_at: timebox_start_date + 5.days)

      expect(response.success?).to eq(true)
      expect(response.payload[:stats]).to eq({
        complete: { count: 1, weight: 1 },
        incomplete: { count: 0, weight: 0 },
        total: { count: 1, weight: 1 }
      })
      expect(response.payload[:burnup_time_series]).to eq(
        [
          {
            date: timebox_start_date,
            scope_count: 1,
            scope_weight: 0,
            completed_count: 0,
            completed_weight: 0
          },
          {
            date: timebox_start_date + 1.day,
            scope_count: 1,
            scope_weight: 2,
            completed_count: 0,
            completed_weight: 0
          },
          {
            date: timebox_start_date + 2.days,
            scope_count: 2,
            scope_weight: 7,
            completed_count: 1,
            completed_weight: 5
          },
          {
            date: timebox_start_date + 3.days,
            scope_count: 2,
            scope_weight: 3,
            completed_count: 1,
            completed_weight: 1
          },
          {
            date: timebox_start_date + 4.days,
            scope_count: 1,
            scope_weight: 1,
            completed_count: 1,
            completed_weight: 1
          }
        ])
    end

    context 'when timebox is removed and then added back' do
      using RSpec::Parameterized::TableSyntax

      where(:event_types, :scope_count) do
        [:add, :add]                        | 1
        [:remove, :remove]                  | 0
        [:add, :add, :remove]               | 0
        [:add, :remove, :remove]            | 0
        [:add, :remove, :add]               | 1
        [:add, :remove, :remove, :add]      | 1
        [:add, :add, :remove, :add, :add]   | 1
      end

      with_them do
        it "updates the counts correspondingly" do
          create_events(event_types, timebox_type)

          expect(response.payload[:burnup_time_series].first&.dig(:scope_count).to_i).to eq(scope_count)
        end
      end
    end

    context 'with scoped_projects' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:subgroup) { create(:group, parent: group) }
      let_it_be(:other_project) { create(:project, group: group) }
      let_it_be(:subgroup_project) { create(:project, group: subgroup) }
      let_it_be(:other_project_issue) { create(:issue, project: other_project) }
      let_it_be(:subgroup_project_issue) { create(:issue, project: subgroup_project) }

      before_all do
        created_at = timebox_start_date - 14.days

        create(:"resource_#{timebox_type}_event", issue: issues[0], timebox_type => timebox, action: :add, created_at: created_at)
        create(:resource_weight_event, issue: issues[0], weight: 1, created_at: created_at)

        create(:"resource_#{timebox_type}_event", issue: issues[1], timebox_type => timebox, action: :add, created_at: created_at)
        create(:resource_weight_event, issue: issues[1], weight: 1, created_at: created_at)

        create(:"resource_#{timebox_type}_event", issue: other_project_issue, timebox_type => timebox, action: :add, created_at: created_at)
        create(:resource_weight_event, issue: other_project_issue, weight: 2, created_at: created_at)

        create(:"resource_#{timebox_type}_event", issue: subgroup_project_issue, timebox_type => timebox, action: :add, created_at: created_at)
        create(:resource_weight_event, issue: subgroup_project_issue, weight: 3, created_at: created_at)
      end

      context 'scoped_projects is blank' do
        where(:scoped_projects) do
          [[[]], [Project.none]]
        end

        with_them do
          it 'returns an empty response' do
            expect(response)
              .to be_success
              .and have_attributes(payload: match(stats: be_nil, burnup_time_series: be_empty))
          end
        end
      end

      where(:scoped_projects, :expected_count, :expected_weight) do
        lazy { [project] }                                  | 2 | 2
        lazy { [other_project] }                            | 1 | 2
        lazy { [subgroup_project] }                         | 1 | 3
        lazy { [project, other_project, subgroup_project] } | 4 | 7
      end

      with_them do
        it "aggregates events scoped to the given projects" do
          expect(response.success?).to eq(true)
          expect(response.payload[:stats]).to eq({
            complete: { count: 0, weight: 0 },
            incomplete: { count: expected_count, weight: expected_weight },
            total: { count: expected_count, weight: expected_weight }
          })

          expect(response.payload[:burnup_time_series]).to eq(
            [
              {
                date: timebox_start_date,
                scope_count: expected_count,
                scope_weight: expected_weight,
                completed_count: 0,
                completed_weight: 0
              }
            ])
        end
      end
    end
  end
end

RSpec.describe TimeboxReportService, :aggregate_failures do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:timebox_start_date) { Date.today }
  let_it_be(:timebox_end_date) { timebox_start_date + 2.weeks }

  let(:scoped_projects) { group.projects }
  let(:response) { described_class.new(timebox, scoped_projects).execute }

  context 'milestone charts' do
    let_it_be(:timebox, reload: true) { create(:milestone, project: project, start_date: timebox_start_date, due_date: timebox_end_date) }
    let_it_be(:another_timebox) { create(:milestone, project: project) }

    let(:timebox_without_dates) { build(:milestone, project: project) }

    it_behaves_like 'timebox chart', 'milestone'
  end

  context 'iteration charts' do
    let_it_be(:cadence) { create(:iterations_cadence, group: group) }
    let_it_be(:timebox, reload: true) { create(:iteration, iterations_cadence: cadence, start_date: timebox_start_date, due_date: timebox_end_date) }
    let_it_be(:another_timebox) { create(:iteration, iterations_cadence: cadence, start_date: timebox_end_date + 1.day, due_date: timebox_end_date + 15.days) }

    let(:timebox_without_dates) { build(:iteration, group: group, start_date: nil, due_date: nil) }

    it_behaves_like 'timebox chart', 'iteration'
  end

  def create_events(event_types, timebox_type)
    event_types.each_with_index do |event_type, index|
      create(:"resource_#{timebox_type}_event", issue: issues[0], timebox_type => timebox, action: event_type, created_at: timebox_start_date + 4.days + (index + 1).seconds)
    end
  end
end
