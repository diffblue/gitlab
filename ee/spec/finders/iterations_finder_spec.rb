# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IterationsFinder, feature_category: :team_planning do
  let_it_be(:root) { create(:group, :private) }
  let_it_be(:group) { create(:group, :private, parent: root) }
  let_it_be(:project_1) { create(:project, namespace: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:iteration_cadence1) { create(:iterations_cadence, group: group, active: true, duration_in_weeks: 1, title: 'one week iterations') }
  let_it_be(:iteration_cadence2) { create(:iterations_cadence, group: group, active: true, duration_in_weeks: 2, title: 'two week iterations') }
  let_it_be(:iteration_cadence3) { create(:iterations_cadence, group: root, active: true, duration_in_weeks: 3, title: 'three week iterations') }

  let_it_be(:closed_iteration) { create(:closed_iteration, :skip_future_date_validation, iterations_cadence: iteration_cadence2, start_date: 7.days.ago, due_date: 2.days.ago, updated_at: 10.days.ago) }
  let_it_be(:started_group_iteration) { create(:current_iteration, :skip_future_date_validation, iterations_cadence: iteration_cadence2, title: 'one test', start_date: 1.day.ago, due_date: Date.today, updated_at: 5.days.ago) }
  let_it_be(:upcoming_group_iteration) { create(:iteration, iterations_cadence: iteration_cadence1, title: 'Iteration 1', start_date: 1.day.from_now, due_date: 3.days.from_now) }
  let_it_be(:root_group_iteration) { create(:current_iteration, iterations_cadence: iteration_cadence3, start_date: 1.day.ago, due_date: 2.days.from_now) }
  let_it_be(:root_closed_iteration) { create(:closed_iteration, iterations_cadence: iteration_cadence3, start_date: 1.week.ago, due_date: 2.days.ago) }

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

    context 'when skipping authorization' do
      let(:params) { { parent: parent } }

      it 'returns iterations' do
        expect(described_class.new(user, params).execute(skip_authorization: true)).not_to be_empty
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

      context 'with filters' do
        context 'by iteration_wildcard_id' do
          let_it_be(:started_group_iteration2) { create(:current_iteration, :skip_future_date_validation, iterations_cadence: iteration_cadence1, group: iteration_cadence1.group, title: 'one test', start_date: 1.day.ago, due_date: Date.today) }

          before do
            params[:iteration_wildcard_id] = 'CURRENT'
          end

          it 'returns CURRENT iterations without ancestors' do
            expect(subject).to contain_exactly(started_group_iteration, started_group_iteration2)
          end

          context 'when iteration_cadence_id is provided' do
            it 'returns CURRENT iteration for the given cadence' do
              params[:iteration_cadence_ids] = iteration_cadence1.id

              expect(subject).to contain_exactly(started_group_iteration2)
            end
          end
        end
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

      it 'filters by current state' do
        params[:state] = 'current'

        expect(subject).to contain_exactly(root_group_iteration, started_group_iteration)
      end

      it 'filters by invalid state' do
        params[:state] = 'started'

        expect { subject }.to raise_error(ArgumentError, "Unknown state filter: started")
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

      context "with search params" do
        using RSpec::Parameterized::TableSyntax

        shared_examples "search returns correct items" do
          before do
            params.merge!({ search: search, in: fields_to_search })
          end

          it { is_expected.to contain_exactly(*expected_iterations) }
        end

        context 'filters by title' do
          let(:all_iterations) { [closed_iteration, started_group_iteration, upcoming_group_iteration, root_group_iteration, root_closed_iteration] }

          where(:search, :fields_to_search, :expected_iterations) do
            ''               | []                       | lazy { all_iterations }
            'iteration'      | []                       | lazy { all_iterations }
            'iteration'      | [:title]                 | lazy { [upcoming_group_iteration] }
            'iteration'      | [:title]                 | lazy { [upcoming_group_iteration] }
            'iter 1'         | [:title]                 | lazy { [upcoming_group_iteration] }
            'iteration 1'    | [:title]                 | lazy { [upcoming_group_iteration] }
            'iteration test' | [:title]                 | lazy { [] }
            'one week iter'  | [:cadence_title]         | lazy { [upcoming_group_iteration] }
            'iteration'      | [:cadence_title]         | lazy { all_iterations }
            'two week'       | [:cadence_title]         | lazy { [closed_iteration, started_group_iteration] }
            'iteration test' | [:cadence_title]         | lazy { [] }
            'one week'       | [:title, :cadence_title] | lazy { [upcoming_group_iteration] }
            'iteration'      | [:title, :cadence_title] | lazy { all_iterations }
            'iteration 1'    | [:title, :cadence_title] | lazy { [upcoming_group_iteration] }
          end

          with_them do
            it_behaves_like "search returns correct items"
          end
        end
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

      context 'by updated_at' do
        it 'returns iterations filtered only by updated_before' do
          params[:updated_before] = 3.days.ago.iso8601

          expect(subject).to contain_exactly(closed_iteration, started_group_iteration)
        end

        it 'returns iterations filtered only by updated_after' do
          params[:updated_after] = 7.days.ago.iso8601

          expect(subject).to contain_exactly(
            started_group_iteration,
            upcoming_group_iteration,
            root_group_iteration,
            root_closed_iteration
          )
        end

        it 'returns iterations filtered by updated_after and updated_before' do
          params.merge!(updated_before: 3.days.ago.iso8601, updated_after: 7.days.ago)

          expect(subject).to contain_exactly(started_group_iteration)
        end
      end

      context 'by iteration_wildcard_id' do
        before do
          params[:iteration_wildcard_id] = 'CURRENT'
        end

        it 'returns CURRENT iterations' do
          expect(subject).to contain_exactly(root_group_iteration, started_group_iteration)
        end

        it 'returns CURRENT iteration for the specified cadence' do
          params[:iteration_cadence_ids] = started_group_iteration.iterations_cadence.id

          expect(subject).to contain_exactly(started_group_iteration)
        end
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

      context 'sorting' do
        let(:cadence1_iterations) { [upcoming_group_iteration] }
        let(:cadence2_iterations) { [closed_iteration, started_group_iteration] }
        let(:cadence3_iterations) { [root_closed_iteration, root_group_iteration] }

        shared_examples 'sorted by the default order' do
          it 'sorts by the default order (due_date, title, id asc)' do
            expect(subject).to eq([closed_iteration, root_closed_iteration, started_group_iteration, root_group_iteration, upcoming_group_iteration])
          end
        end

        it_behaves_like 'sorted by the default order'

        context 'when an unsupported sorting param is provided' do
          before do
            params[:sort] = :unsupported
          end

          it_behaves_like 'sorted by the default order'
        end

        it 'sorts correctly by cadence_and_due_date_asc' do
          params[:sort] = :cadence_and_due_date_asc

          expect(subject).to eq([*cadence1_iterations, *cadence2_iterations, *cadence3_iterations])
        end

        it 'sorts correctly by cadence_and_due_date_desc' do
          params[:sort] = :cadence_and_due_date_desc

          expect(subject).to eq([*cadence1_iterations.reverse, *cadence2_iterations.reverse, *cadence3_iterations.reverse])
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
