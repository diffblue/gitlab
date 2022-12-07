# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::BoardListIssuesResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:board) { create(:board, project: project) }
  let_it_be(:label) { create(:label, project: project) }
  let_it_be(:list) { create(:list, board: board, label: label) }

  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:iteration_cadence1) { create(:iterations_cadence, group: group) }
  let_it_be(:iteration_cadence2) { create(:iterations_cadence, group: group) }
  let_it_be(:iteration) { create(:iteration, :with_title, start_date: 1.week.ago, due_date: 2.days.ago, iterations_cadence: iteration_cadence1) }
  let_it_be(:current_iteration) { create(:iteration, start_date: Date.yesterday, due_date: 1.day.from_now, iterations_cadence: iteration_cadence2) }

  let_it_be(:issue1) { create(:issue, project: project, labels: [label], weight: 3, health_status: 'at_risk') }
  let_it_be(:issue2) { create(:issue, project: project, labels: [label], iteration: iteration) }
  let_it_be(:issue3) { create(:issue, project: project, labels: [label], health_status: 'on_track') }
  let_it_be(:issue4) { create(:issue, project: project, labels: [label], iteration: current_iteration, weight: 1, health_status: 'needs_attention') }

  let_it_be(:epic_issue) { create(:epic_issue, epic: epic, issue: issue1) }

  before_all do
    group.add_developer(user)
  end

  shared_examples 'raises error on mutually exclusive arguments' do
    it 'generates an error if mutually exclusive arguments are present' do
      expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError) do
        resolve_board_list_issues({ filters: filters })
      end
    end
  end

  describe '#resolve' do
    context 'filtering by epic' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when providing mutually exclusive filters' do
        let(:filters) { { epic_id: epic.to_global_id, epic_wildcard_id: 'NONE' } }

        it_behaves_like 'raises error on mutually exclusive arguments'
      end

      it 'accepts epic global id' do
        result = resolve_board_list_issues({ filters: { epic_id: epic.to_global_id } })

        expect(result).to contain_exactly(issue1)
      end

      it 'accepts epic wildcard id' do
        result = resolve_board_list_issues({ filters: { epic_wildcard_id: 'NONE' } })

        expect(result).to contain_exactly(issue2, issue3, issue4)
      end
    end

    context 'filtering by weight' do
      it 'accepts weight wildcard id none' do
        result = resolve_board_list_issues({ filters: { weight_wildcard_id: 'NONE' } })

        expect(result).to contain_exactly(issue2, issue3)
      end

      it 'accepts weight wildcard id any' do
        result = resolve_board_list_issues({ filters: { weight_wildcard_id: 'ANY' } })

        expect(result).to contain_exactly(issue1, issue4)
      end

      it 'filters by weight' do
        result = resolve_board_list_issues({ filters: { weight: '3' } })

        expect(result).to contain_exactly(issue1)
      end

      context 'when providing mutually exclusive filters' do
        let(:filters) { { weight: 5, weight_wildcard_id: 'ANY' } }

        it_behaves_like 'raises error on mutually exclusive arguments'
      end

      context 'filtering by negated weight' do
        it 'filters by negated weight' do
          result = resolve_board_list_issues({ filters: { not: { weight: '3' } } })

          expect(result).to contain_exactly(issue2, issue3, issue4)
        end
      end
    end

    context 'filtering by iteration' do
      it 'accepts iteration title' do
        result = resolve_board_list_issues({ filters: { iteration_title: iteration.title } })

        expect(result).to contain_exactly(issue2)
      end

      it 'accepts iteration id' do
        result = resolve_board_list_issues({ filters: { iteration_id: [iteration.to_global_id] } })

        expect(result).to contain_exactly(issue2)
      end

      context 'when filtering by wildcard id' do
        it 'filters by iteration NONE' do
          result = resolve_board_list_issues({ filters: { iteration_wildcard_id: 'NONE' } })

          expect(result).to contain_exactly(issue1, issue3)
        end

        it 'filters by iteration current and cadence id' do
          another_current_iteration = create(:iteration, start_date: Date.yesterday, due_date: 1.day.from_now, iterations_cadence: iteration_cadence1)
          another_current_iteration_issue = create(:issue, project: project, iteration: another_current_iteration, labels: [label])

          result = resolve_board_list_issues({ filters: { iteration_wildcard_id: 'CURRENT', iteration_cadence_id: [iteration_cadence1.to_global_id] } })

          expect(result).to contain_exactly(another_current_iteration_issue)
        end
      end

      context 'filtering by negated iteration' do
        it 'accepts iteration wildcard id' do
          result = resolve_board_list_issues({ filters: { not: { iteration_wildcard_id: 'CURRENT' } } })

          expect(result).to contain_exactly(issue1, issue3, issue2)
        end
      end
    end

    context 'filtering by iteration cadence' do
      it 'returns issues associated with an iteration cadence' do
        result = resolve_board_list_issues({ filters: { iteration_cadence_id: [iteration.iterations_cadence.to_global_id] } })

        expect(result).to contain_exactly(issue2)
      end
    end

    context 'filtering by iids' do
      it 'filters by iids' do
        result = resolve_board_list_issues({ filters: { iids: [issue1.iid, issue3.iid] } })

        expect(result).to contain_exactly(issue1, issue3)
      end

      context 'filtering by negated iids' do
        it 'filters by negated iid' do
          result = resolve_board_list_issues({ filters: { not: { iids: [issue1.iid, issue3.iid] } } })

          expect(result).to contain_exactly(issue2, issue4)
        end
      end
    end

    describe 'filter by health status' do
      context 'when filtering by specific health status' do
        it 'only returns issues that are at risk' do
          expect(resolve_board_list_issues({ filters: { health_status_filter: Issue.health_statuses[:at_risk] } })).to contain_exactly(issue1)
        end

        it 'only returns issues that need attention' do
          expect(resolve_board_list_issues({ filters: { health_status_filter: Issue.health_statuses[:needs_attention] } })).to contain_exactly(issue4)
        end

        it 'only returns issues that are on track' do
          expect(resolve_board_list_issues({ filters: { health_status_filter: Issue.health_statuses[:on_track] } })).to contain_exactly(issue3)
        end
      end

      context 'when filtering by any health status' do
        specify { expect(resolve_board_list_issues({ filters: { health_status_filter: 'any' } })).to contain_exactly(issue1, issue3, issue4) }
      end

      context 'when filtering by no health status' do
        specify { expect(resolve_board_list_issues({ filters: { health_status_filter: 'none' } })).to contain_exactly(issue2) }
      end

      context 'when filtering by negated health status' do
        let(:filters) { { not: { health_status_filter: Issue.health_statuses[:at_risk] } } }

        specify { expect(resolve_board_list_issues({ filters: filters })).to contain_exactly(issue2, issue3, issue4) }
      end
    end
  end

  def resolve_board_list_issues(args)
    resolve(described_class, obj: list, args: args, ctx: { current_user: user }, arg_style: :internal)
  end
end
