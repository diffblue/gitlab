# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IterationsFinder do
  let_it_be(:root) { create(:group, :private) }
  let_it_be(:group) { create(:group, :private, parent: root) }
  let_it_be(:project_1) { create(:project, namespace: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:iteration_cadence1) { create(:iterations_cadence, group: group, active: true, duration_in_weeks: 1, title: 'one week iterations') }
  let_it_be(:iteration_cadence2) { create(:iterations_cadence, group: group, active: true, duration_in_weeks: 2, title: 'two week iterations') }
  let_it_be(:iteration_cadence3) { create(:iterations_cadence, group: root, active: true, duration_in_weeks: 3, title: 'three week iterations') }
  let_it_be(:closed_iteration) { create(:closed_iteration, :skip_future_date_validation, iterations_cadence: iteration_cadence2, group: iteration_cadence2.group, start_date: 7.days.ago, due_date: 2.days.ago) }
  let_it_be(:started_group_iteration) { create(:current_iteration, :skip_future_date_validation, iterations_cadence: iteration_cadence2, group: iteration_cadence2.group, title: 'one test', start_date: 1.day.ago, due_date: Date.today) }
  let_it_be(:upcoming_group_iteration) { create(:iteration, iterations_cadence: iteration_cadence1, group: iteration_cadence1.group, start_date: 1.day.from_now, due_date: 3.days.from_now) }
  let_it_be(:root_group_iteration) { create(:current_iteration, iterations_cadence: iteration_cadence3, group: iteration_cadence3.group, start_date: 1.day.ago, due_date: 2.days.from_now) }
  let_it_be(:root_closed_iteration) { create(:closed_iteration, iterations_cadence: iteration_cadence3, group: iteration_cadence3.group, start_date: 1.week.ago, due_date: 2.days.ago) }

  let(:parent) { project_1 }
  let(:params) { { parent: parent, include_ancestors: true } }

  subject { described_class.new(user, params).execute }

  context 'without permissions' do
    context 'with project as parent' do
      let(:params) { { parent: parent } }

      it 'returns none' do
        expect(subject).to be_empty
      end
    end

    context 'with group as parent' do
      let(:params) { { parent: group } }

      it 'returns none' do
        expect(subject).to be_empty
      end
    end
  end

  context 'with permissions' do
    before do
      group.add_reporter(user)
      project_1.add_reporter(user)
    end

    context 'iterations fetched from project' do
      let(:params) { { parent: parent } }

      it 'returns iterations for projects' do
        expect(subject).to contain_exactly(closed_iteration, started_group_iteration, upcoming_group_iteration)
      end
    end

    context 'iterations fetched from group' do
      let(:params) { { parent: group } }

      it 'returns iterations for groups' do
        expect(subject).to contain_exactly(closed_iteration, started_group_iteration, upcoming_group_iteration)
      end
    end

    context 'iterations for project with ancestors' do
      it 'returns iterations for project and ancestor groups' do
        expect(subject).to contain_exactly(root_closed_iteration, root_group_iteration, closed_iteration, started_group_iteration, upcoming_group_iteration)
      end

      it 'orders iterations by due date and title' do
        expect(subject.to_a).to eq([closed_iteration, root_closed_iteration, started_group_iteration, root_group_iteration, upcoming_group_iteration].sort_by { |a| [a.due_date, a.title, a.id] })
      end
    end

    context 'with filters' do
      it 'filters by all states' do
        params[:state] = 'all'

        expect(subject).to contain_exactly(root_closed_iteration, root_group_iteration, closed_iteration, started_group_iteration, upcoming_group_iteration)
      end

      it 'filters by started state' do
        params[:state] = 'current'

        expect(subject).to contain_exactly(root_group_iteration, started_group_iteration)
      end

      it 'filters by opened state' do
        params[:state] = 'opened'

        expect(subject).to contain_exactly(upcoming_group_iteration, root_group_iteration, started_group_iteration)
      end

      it 'filters by closed state' do
        params[:state] = 'closed'

        expect(subject).to contain_exactly(root_closed_iteration, closed_iteration)
      end

      it 'filters by title' do
        params[:title] = 'one test'

        expect(subject.to_a).to contain_exactly(started_group_iteration)
      end

      it 'filters by search_title' do
        params[:search_title] = 'one t'

        expect(subject.to_a).to contain_exactly(started_group_iteration)
      end

      it 'filters by ID' do
        params[:id] = upcoming_group_iteration.id

        expect(subject).to contain_exactly(upcoming_group_iteration)
      end

      it 'filters by cadence' do
        params[:iteration_cadence_ids] = iteration_cadence1.id

        expect(subject).to contain_exactly(upcoming_group_iteration)
      end

      it 'filters by multiple cadences' do
        params[:iteration_cadence_ids] = [iteration_cadence1.id, iteration_cadence2.id]

        expect(subject).to contain_exactly(closed_iteration, started_group_iteration, upcoming_group_iteration)
      end

      context 'by timeframe' do
        it 'returns iterations with start_date and due_date between timeframe' do
          params.merge!(start_date: 1.day.ago, end_date: 3.days.from_now)

          expect(subject).to match_array([started_group_iteration, upcoming_group_iteration, root_group_iteration])
        end

        it 'returns iterations which start before the timeframe' do
          params.merge!(start_date: 3.days.ago, end_date: 2.days.ago)

          expect(subject).to match_array([closed_iteration, root_closed_iteration])
        end

        it 'returns iterations which end after the timeframe' do
          params.merge!(start_date: 3.days.from_now, end_date: 5.days.from_now)

          expect(subject).to match_array([upcoming_group_iteration])
        end

        describe 'when one of the timeframe params are missing' do
          it 'does not filter by timeframe if start_date is missing' do
            only_end_date = described_class.new(user, params.merge(end_date: 1.year.ago)).execute

            expect(only_end_date).to eq(subject)
          end

          it 'does not filter by timeframe if end_date is missing' do
            only_start_date = described_class.new(user, params.merge(start_date: 1.year.from_now)).execute

            expect(only_start_date).to eq(subject)
          end
        end
      end
    end

    describe '#find_by' do
      it 'finds a single iteration' do
        finder = described_class.new(user, parent: project_1)

        expect(finder.find_by(iid: upcoming_group_iteration.iid)).to eq(upcoming_group_iteration)
      end
    end
  end
end
