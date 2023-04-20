# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Timebox::SnapshotBuilder, :aggregate_failures, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  shared_examples 'builds snapshots for timebox' do
    context 'when no resource event exists' do
      it 'returns an empty array' do
        expect(snapshots).to eq([])
      end
    end

    context 'when resource events exist' do
      context 'when issue is assigned to a timebox' do
        let_it_be(:issue) { create(:issue, project: project, title: 'issue') }
        let_it_be(:task) { create(:work_item, :task, project: project, title: 'task') }

        it 'builds a correct snapshot' do
          travel_to timebox.start_date do
            assign_timebox(issue, timebox)

            expect(snapshots).to have_snapshot(
              timebox.start_date,
              [{
                item_id: issue.id,
                timebox_id: timebox.id
              }]
            )
          end
        end

        context 'when issue is assigned to timebox after the end of the timebox' do
          it 'does not consider the issue' do
            travel_to timebox.due_date + 1.hour do
              assign_timebox(issue, timebox)
            end

            travel_to timebox.due_date do
              expect(snapshots).to have_snapshot(timebox.due_date, [])
            end
          end
        end

        context 'when it is not yet the due date of the timebox' do
          it 'only builds the snapshots up to the current date' do
            travel_to timebox.start_date + 1.day do
              assign_timebox(issue, timebox)

              expect(snapshots.size).to eq(2)
              expect(snapshots).to have_snapshot(timebox.start_date, [])
              expect(snapshots).to have_snapshot(timebox.start_date + 1.day, [{
                item_id: issue.id,
                timebox_id: timebox.id
              }])
            end
          end
        end

        context 'when issue is assigned to timebox prior to the start of the timebox' do
          it 'builds a correct snapshot' do
            travel_to timebox.start_date - 5.days do
              assign_timebox(issue, timebox)
            end

            travel_to timebox.start_date do
              expect(snapshots).to have_snapshot(
                timebox.start_date,
                [{
                  item_id: issue.id,
                  timebox_id: timebox.id
                }]
              )
            end
          end
        end

        context 'when issue is given a weight then closes' do
          it 'builds a correct snapshot' do
            travel_to timebox.start_date do
              assign_timebox(issue, timebox)
              weight(issue, 1)
              close(issue)

              expect(snapshots).to have_snapshot(
                timebox.start_date,
                [{
                  item_id: issue.id,
                  timebox_id: timebox.id,
                  weight: 1,
                  start_state: ResourceStateEvent.states[:opened],
                  end_state: ResourceStateEvent.states[:closed]
                }]
              )
            end
          end
        end

        context 'when issue is given a weight then closes on another day' do
          it 'builds a correct snapshot' do
            travel_to timebox.start_date do
              assign_timebox(issue, timebox)

              expect(snapshots).to have_snapshot(
                timebox.start_date,
                [{
                  item_id: issue.id,
                  timebox_id: timebox.id
                }]
              )
            end

            travel_to(timebox.start_date + 1.day) do
              weight(issue, 1)
              close(issue)

              expect(snapshots).to have_snapshot(
                timebox.start_date + 1.day,
                [{
                  item_id: issue.id,
                  timebox_id: timebox.id,
                  weight: 1,
                  start_state: ResourceStateEvent.states[:opened],
                  end_state: ResourceStateEvent.states[:closed]
                }])
            end
          end

          context 'when issue is re-opened on the final day' do
            it 'builds a correct snapshot' do
              travel_to timebox.start_date do
                assign_timebox(issue, timebox)

                expect(snapshots).to have_snapshot(
                  timebox.start_date,
                  [{
                    item_id: issue.id,
                    timebox_id: timebox.id
                  }])
              end

              travel_to timebox.start_date + 1.day do
                weight(issue, 1)
                close(issue)

                expect(snapshots).to have_snapshot(
                  timebox.start_date + 1.day,
                  [{
                    item_id: issue.id,
                    timebox_id: timebox.id,
                    weight: 1,
                    start_state: ResourceStateEvent.states[:opened],
                    end_state: ResourceStateEvent.states[:closed]
                  }])
              end

              travel_to timebox.due_date do
                reopen(issue)

                expect(snapshots).to have_snapshot(
                  timebox.due_date,
                  [{
                    item_id: issue.id,
                    timebox_id: timebox.id,
                    weight: 1,
                    start_state: ResourceStateEvent.states[:closed],
                    end_state: ResourceStateEvent.states[:reopened]
                  }])
              end
            end
          end
        end

        context 'when issue has a child task' do
          it 'builds a correct snapshot' do
            travel_to timebox.start_date do
              assign_timebox(issue, timebox)
              link(parent: issue, child: task)

              expect(snapshots).to have_snapshot(
                timebox.start_date,
                [{
                  item_id: issue.id,
                  timebox_id: timebox.id,
                  children_ids: Set.new([task.id])
                },
                  {
                    item_id: task.id,
                    timebox_id: nil,
                    parent_id: issue.id
                  }])
            end
          end

          context 'when a child task is added to the timebox' do
            it 'builds a correct snapshot' do
              travel_to timebox.start_date do
                assign_timebox(issue, timebox)
                link(parent: issue, child: task)
                assign_timebox(task, timebox)

                expect(snapshots).to have_snapshot(
                  timebox.start_date,
                  [{
                    item_id: issue.id,
                    timebox_id: timebox.id,
                    weight: 0,
                    children_ids: Set.new([task.id])
                  },
                    {
                      item_id: task.id,
                      timebox_id: timebox.id,
                      weight: 0,
                      parent_id: issue.id
                    }])
              end
            end
          end

          context 'when a child task is added to and remove from the timebox' do
            it 'builds a correct snapshot' do
              travel_to timebox.start_date do
                assign_timebox(issue, timebox)
                link(parent: issue, child: task)

                expect(snapshots).to have_snapshot(
                  timebox.start_date,
                  [{
                    item_id: issue.id,
                    timebox_id: timebox.id,
                    children_ids: Set.new([task.id])
                  },
                    {
                      item_id: task.id,
                      timebox_id: nil,
                      parent_id: issue.id
                    }])
              end

              travel_to timebox.start_date + 1.day do
                unlink(parent: issue, child: task)

                expect(snapshots).to have_snapshot(
                  timebox.start_date + 1.day,
                  [{
                    item_id: issue.id,
                    timebox_id: timebox.id,
                    children_ids: Set.new
                  },
                    {
                      item_id: task.id,
                      timebox_id: nil,
                      parent_id: nil
                    }])
              end
            end
          end
        end
      end

      context 'when multiple issues and tasks exist' do
        let_it_be(:issue1) { create(:issue, project: project, title: 'issue1') }
        let_it_be(:issue2) { create(:issue, project: project, title: 'issue2') }
        let_it_be(:task1) { create(:work_item, :task, project: project, title: 'task1') }
        let_it_be(:task2) { create(:work_item, :task, project: project, title: 'task2') }

        context 'when issue is moved from one timebox to another timebox' do
          it 'builds a correct snapshot' do
            travel_to(timebox.start_date - 1.day) do
              # `issue1` is assigned to `timebox` and weighed at 1.
              assign_timebox(issue1, timebox)
              link(parent: issue1, child: task1)

              # `issue2` is assigned to another timebox (shouldn't count for now.)
              assign_timebox(issue2, next_timebox)
              link(parent: issue2, child: task2)
            end

            travel_to timebox.start_date do
              expect(snapshots).to have_snapshot(
                timebox.start_date,
                [{
                  item_id: issue1.id,
                  timebox_id: timebox.id,
                  children_ids: Set.new([task1.id])
                },
                  {
                    item_id: task1.id,
                    timebox_id: nil,
                    parent_id: issue1.id
                  }])
            end

            travel_to timebox.due_date do
              link(parent: issue2, child: task2)
              assign_timebox(issue2, timebox) # Now issue2 and task2 should be accounted for in the daily snapshot.

              expect(snapshots).to have_snapshot(
                timebox.due_date,
                [{
                  item_id: issue1.id,
                  timebox_id: timebox.id,
                  children_ids: Set.new([task1.id])
                },
                  {
                    item_id: task1.id,
                    timebox_id: nil,
                    parent_id: issue1.id
                  },
                  {
                    item_id: issue2.id,
                    timebox_id: timebox.id,
                    children_ids: Set.new([task2.id])
                  },
                  {
                    item_id: task2.id,
                    timebox_id: nil,
                    parent_id: issue2.id
                  }])
            end
          end
        end

        # Tests a more complex setup.
        context 'with an integrated scenario 1' do
          it 'builds a correct snapshot' do
            travel_to(timebox.start_date - 1.day) do
              # `issue1` is assigned to `timebox` and weighed at 1.
              assign_timebox(issue1, timebox)
              weight(issue1, 1)

              # `issue2` is assigned to another timebox (shouldn't count for now.)
              assign_timebox(issue2, next_timebox)
              weight(issue2, 10)
            end

            travel_to timebox.start_date do
              # `task1` is weighed at 2 and linked to `issue1` but not to `timebox` itself.
              link(parent: issue1, child: task1)
              weight(task1, 2)

              expect(snapshots).to have_snapshot(
                timebox.start_date,
                [{
                  item_id: issue1.id,
                  timebox_id: timebox.id,
                  weight: 1,
                  children_ids: Set.new([task1.id])
                },
                  {
                    item_id: task1.id,
                    timebox_id: nil,
                    weight: 2,
                    parent_id: issue1.id
                  }])
            end

            travel_to timebox.start_date + 1.day do
              weight(issue1, 100)

              link(parent: issue2, child: task2)
              assign_timebox(issue2, timebox) # Now issue2 and task2 should be accounted for in the daily snapshot.

              close(issue1)
              close(task1)

              reopen(issue1, extra_ts_offset: 1.hour)
              reopen(task1, extra_ts_offset: 1.hour)

              expect(snapshots).to have_snapshot(
                timebox.start_date + 1.day,
                [{
                  item_id: issue1.id,
                  timebox_id: timebox.id,
                  weight: 100,
                  start_state: ResourceStateEvent.states[:opened],
                  end_state: ResourceStateEvent.states[:reopened],
                  children_ids: Set.new([task1.id])
                },
                  {
                    item_id: task1.id,
                    timebox_id: nil,
                    weight: 2,
                    start_state: ResourceStateEvent.states[:opened],
                    end_state: ResourceStateEvent.states[:reopened],
                    parent_id: issue1.id
                  },
                  {
                    item_id: issue2.id,
                    timebox_id: timebox.id,
                    weight: 10,
                    children_ids: Set.new([task2.id])
                  },
                  {
                    item_id: task2.id,
                    timebox_id: nil,
                    parent_id: issue2.id
                  }])
            end

            travel_to timebox.due_date do
              close(issue1)
              close(issue2)
              close(task1)
              close(task2)
            end

            travel_to timebox.due_date + 1.day do
              # These should have no effect on the snapshot taken for timebox.due_date
              weight(issue1, 0)
              weight(issue2, 0)
              weight(task1, 0)
              weight(task2, 0)
              reopen(issue1)
              reopen(issue2)
              reopen(task1)
              reopen(task2)

              expect(snapshots).to have_snapshot(
                timebox.due_date,
                [{
                  item_id: issue1.id,
                  timebox_id: timebox.id,
                  weight: 100,
                  start_state: ResourceStateEvent.states[:reopened],
                  end_state: ResourceStateEvent.states[:closed],
                  children_ids: Set.new([task1.id])
                },
                  {
                    item_id: task1.id,
                    timebox_id: nil,
                    weight: 2,
                    start_state: ResourceStateEvent.states[:reopened],
                    end_state: ResourceStateEvent.states[:closed],
                    parent_id: issue1.id
                  },
                  {
                    item_id: issue2.id,
                    timebox_id: timebox.id,
                    weight: 10,
                    start_state: ResourceStateEvent.states[:opened],
                    end_state: ResourceStateEvent.states[:closed],
                    children_ids: Set.new([task2.id])
                  },
                  {
                    item_id: task2.id,
                    timebox_id: nil,
                    start_state: ResourceStateEvent.states[:opened],
                    end_state: ResourceStateEvent.states[:closed],
                    parent_id: issue2.id
                  }])
            end
          end
        end
      end
    end
  end

  describe 'checking arguments' do
    let(:timebox) { build_stubbed(:milestone) }

    it 'raises ArgumentError when timebox is not Milestone or Iteration' do
      expect { described_class.new(Class.new, Class.new).build }
        .to raise_error(Gitlab::Timebox::SnapshotBuilder::ArgumentError)
    end

    it 'raises ArgumentError when resource_events is not PG::Result' do
      expect { described_class.new(timebox, Class.new).build }
        .to raise_error(Gitlab::Timebox::SnapshotBuilder::ArgumentError)
    end

    it 'raises FieldsError when resource_events do not select the correct columns' do
      pg_query_result = ApplicationRecord.connection.execute("SELECT id FROM issues")

      expect { described_class.new(timebox, pg_query_result).build }
        .to raise_error(Gitlab::Timebox::SnapshotBuilder::FieldsError)
    end
  end

  context 'when timebox is milestone' do
    it_behaves_like 'builds snapshots for timebox' do
      # rubocop:disable Layout/LineLength
      let_it_be(:resource_timebox_event) { ResourceMilestoneEvent }
      let_it_be(:resource_timebox_factory) { resource_timebox_event.name.underscore.to_sym }
      let_it_be(:timebox) { create(:milestone, project: project, start_date: Date.current, due_date: Date.current + 6.days) }
      let_it_be(:next_timebox) { create(:milestone, project: project, start_date: Date.current + 7.days, due_date: Date.current + 13.days) }
      let_it_be(:timebox_type) { :milestone }
      # rubocop:enable Layout/LineLength
    end
  end

  context 'when timebox is iteration' do
    let_it_be(:cadence) { create(:iterations_cadence, group: group) }

    it_behaves_like 'builds snapshots for timebox' do
      # rubocop:disable Layout/LineLength
      let_it_be(:resource_timebox_event) { ResourceIterationEvent }
      let_it_be(:resource_timebox_factory) { resource_timebox_event.name.underscore.to_sym }
      let_it_be(:timebox) { create(:iteration, iterations_cadence: cadence, start_date: Date.current, due_date: Date.current + 6.days) }
      let_it_be(:next_timebox) { create(:iteration, iterations_cadence: cadence, start_date: Date.current + 7.days, due_date: Date.current + 13.days) }
      let_it_be(:timebox_type) { :iteration }
      # rubocop:enable Layout/LineLength
    end
  end

  def resource_events
    union_query = [
      WorkItems::ResourceLinkEvent, ResourceStateEvent, ResourceWeightEvent, resource_timebox_event
    ].map(&:aliased_for_timebox_report).map(&:to_sql).join(' union ')

    ApplicationRecord.connection.execute("SELECT * FROM (#{union_query}) as query ORDER BY created_at ASC")
  end

  def snapshots
    described_class.new(timebox, resource_events).build
  end

  def assign_timebox(item, timebox)
    create(resource_timebox_factory, issue: item, timebox_type => timebox)
  end

  def weight(item, weight)
    create(:resource_weight_event, issue: item, weight: weight)
  end

  def close(item, extra_ts_offset: 0.hours)
    create(:resource_state_event, issue: item, state: :closed, created_at: Time.current + extra_ts_offset)
  end

  def reopen(item, extra_ts_offset: 0.hours)
    create(:resource_state_event, issue: item, state: :reopened, created_at: Time.current + extra_ts_offset)
  end

  def link(parent:, child:)
    create(:resource_link_event, issue: parent, child_work_item: child)
  end

  def unlink(parent:, child:)
    create(:resource_link_event, action: 'remove', issue: parent, child_work_item: child)
  end
end
