# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::BoardGroupings::EpicsResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:parent_group) { create(:group, :private) }
  let_it_be(:group) { create(:group, :private, parent: parent_group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:other_project) { create(:project, group: group) }
  let_it_be(:board) { create(:board, project: project) }
  let_it_be(:group_board) { create(:board, group: group) }

  let_it_be(:label1) { create(:label, project: project, name: 'foo') }
  let_it_be(:label2) { create(:label, project: project, name: 'bar') }
  let_it_be(:list) { create(:list, board: board, label: label1) }

  let_it_be(:issue1) { create(:issue, project: project, labels: [label1]) }
  let_it_be(:issue2) { create(:issue, :confidential, project: project, labels: [label1, label2]) }
  let_it_be(:issue3) { create(:issue, project: other_project) }

  let_it_be(:epic1) { create(:epic, group: parent_group) }
  let_it_be(:epic2) { create(:epic, :confidential, group: group) }
  let_it_be(:epic3) { create(:epic, group: group) }

  let_it_be(:epic_issue1) { create(:epic_issue, epic: epic1, issue: issue1) }
  let_it_be(:epic_issue2) { create(:epic_issue, epic: epic2, issue: issue2) }
  let_it_be(:epic_issue3) { create(:epic_issue, epic: epic3, issue: issue3) }

  let(:context) do
    GraphQL::Query::Context.new(
      query: query_double(schema: nil),
      values: { current_user: current_user },
      object: nil
    )
  end

  shared_examples '#resolve' do
    before do
      stub_licensed_features(epics: true)
    end

    context 'when user can not see epics' do
      it 'does not return epics' do
        result = resolve_board_epics(board)

        expect(result).to match_array([])
      end
    end

    context 'when user can access the group' do
      before do
        parent_group.add_developer(current_user)
      end

      it 'finds all epics for issues in the project board' do
        result = resolve_board_epics(board)

        # WithIssueFinders takes care of ordering and orders based on descending epics.id.
        # The other query does not take care of ordering as it's done with our GraphQL Pagination.
        expect(result).to match_array([epic1, epic2])
      end

      it 'finds all epics for issues in the group board' do
        result = resolve_board_epics(group_board)

        # WithIssueFinders takes care of ordering and orders based on descending epics.id.
        # The other query does not take care of ordering as it's done with our GraphQL Pagination.
        expect(result).to match_array([epic1, epic2, epic3])
      end

      it 'finds only epics for issues matching issue filters' do
        result = resolve_board_epics(
          group_board, { issue_filters: { label_name: [label1.title], not: { label_name: [label2.title] } } })

        expect(result).to match_array([epic1])
      end

      it 'finds only epics for issues matching search param' do
        result = resolve_board_epics(
          group_board, { issue_filters: { search: issue1.title } })

        expect(result).to match_array([epic1])
      end

      it 'generates an error if both epic_id and epic_wildcard_id are present' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError) do
          resolve_board_epics(group_board, { issue_filters: { epic_id: epic1.to_global_id, epic_wildcard_id: 'NONE' } })
        end
      end

      it 'calls service with right params' do
        filters = { label_name: ['foo'], not: { label_name: %w(foo bar) } }
        service_params = { all_lists: true, board_id: group_board.id }.merge(filters)

        expect(Boards::Issues::ListService).to receive(:new)
          .with(group_board.resource_parent, current_user, service_params)
          .and_call_original

        resolve_board_epics(group_board, { issue_filters: filters })
      end

      it 'accepts epic global id' do
        result = resolve_board_epics(
          group_board, { issue_filters: { epic_id: epic1.to_global_id } })

        expect(result).to match_array([epic1])
      end

      it 'accepts epic wildcard id' do
        result = resolve_board_epics(
          group_board, { issue_filters: { epic_wildcard_id: 'NONE' } })

        expect(result).to match_array([])
      end
    end

    context 'when user is a group guest' do
      before do
        parent_group.add_guest(current_user)
      end

      it 'finds non-confidental epics for issues in the project board' do
        result = resolve_board_epics(board)

        expect(result).to match_array([epic1])
      end

      it 'finds non-confidental epics for issues in the group board' do
        result = resolve_board_epics(group_board)

        expect(result).to match_array([epic1, epic3])
      end
    end
  end

  context 'when board_grouped_by_epic_performance is turned on' do
    before do
      stub_feature_flags(board_grouped_by_epic_performance: true)
    end

    it_behaves_like '#resolve'

    context 'with issue filters' do
      before do
        stub_licensed_features(epics: true)
        parent_group.add_developer(current_user)
      end

      context 'when issue filters are set' do
        it 'does not call the Epics::WithIssuesFinder' do
          filters = { label_name: ['foo'] }

          expect(::Epics::WithIssuesFinder).not_to receive(:new)

          resolve_board_epics(group_board, { issue_filters: filters })
        end
      end

      context 'when there are no issue filters' do
        it 'call the Epics::WithIssuesFinder and orders the result' do
          expect(::Epics::WithIssuesFinder).to receive(:new).and_call_original

          resolve_board_epics(group_board)
        end

        it 'orders by descending epics.id' do
          result = resolve_board_epics(group_board)

          expect(result).to eq([epic3, epic2, epic1])
        end
      end
    end
  end

  context 'when board_grouped_by_epic_performance is turned off' do
    before do
      stub_feature_flags(board_grouped_by_epic_performance: false)
    end

    it_behaves_like '#resolve'
  end

  def resolve_board_epics(object, args = {})
    resolve(described_class, obj: object, args: args, ctx: context)
  end
end
