# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'get list of epics for an epic board list', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:development) { create(:group_label, group: group, name: 'Development') }
  let_it_be(:staging) { create(:group_label, group: group, name: 'Staging') }
  let_it_be(:extra_label1) { create(:group_label, group: group, name: 'Extra label1') }
  let_it_be(:extra_label2) { create(:group_label, group: group, name: 'Extra label2') }
  let_it_be(:board) { create(:epic_board, group: group) }
  let_it_be(:list) { create(:epic_list, epic_board: board, label: development) }

  let_it_be(:epic1) { create(:labeled_epic, group: group, labels: [development, extra_label1]) }
  let_it_be(:epic2) { create(:labeled_epic, group: group, labels: [development, extra_label2]) }
  let_it_be(:epic3) { create(:labeled_epic, group: group, labels: [development, staging], author: current_user) }
  let_it_be(:epic4) { create(:labeled_epic, group: group) }

  let_it_be(:epic_pos1) { create(:epic_board_position, epic: epic1, epic_board: board, relative_position: 20) }
  let_it_be(:epic_pos2) { create(:epic_board_position, epic: epic2, epic_board: board, relative_position: 10) }

  let(:data_path) { [:group, :epicBoard, :lists, :nodes, 0, :epics] }

  def pagination_query(params = {})
    graphql_query_for(:group, { full_path: group.full_path },
      <<~BOARDS
        epicBoard(id: "#{board.to_global_id}") {
          lists(id: "#{list.to_global_id}") {
            nodes {
              #{query_nodes(:epics, epic_fields, include_pagination_info: true, args: params)}
            }
          }
        }
      BOARDS
    )
  end

  before do
    stub_licensed_features(epics: true)
    group.add_developer(current_user)
  end

  describe 'sorting and pagination' do
    let(:epic_fields) { all_graphql_fields_for('epics'.classify) }
    let(:all_records) { [epic2.to_global_id.to_s, epic1.to_global_id.to_s, epic3.to_global_id.to_s] }

    it_behaves_like 'sorted paginated query' do
      include_context 'no sort argument'

      let(:first_param) { 2 }
    end
  end

  context 'with filters' do
    let(:epic_fields) { 'id' }

    it 'finds only epics matching the filter' do
      filter_params = { filters: { author_username: current_user.username, label_name: [staging.title] } }
      query = pagination_query(filter_params)

      post_graphql(query, current_user: current_user)

      boards = graphql_data_at(*data_path, :nodes)
      expect(boards).to contain_exactly(a_graphql_entity_for(epic3))
    end

    context 'when negated' do
      it 'finds only epics matching the negated filter' do
        filter_params = { filters: { not: { label_name: [staging.title] } } }
        query = pagination_query(filter_params)

        post_graphql(query, current_user: current_user)

        boards = graphql_data_at(*data_path, :nodes)
        expect(boards).to contain_exactly(a_graphql_entity_for(epic1), a_graphql_entity_for(epic2))
      end
    end

    context 'when using OR label filter' do
      let(:filter_params) { { filters: { or: { label_name: [extra_label1.title, extra_label2.title] } } } }

      it 'finds only epics matching at least one of the labels' do
        post_graphql(pagination_query(filter_params), current_user: current_user)

        boards = graphql_data_at(*data_path, :nodes)
        expect(boards).to contain_exactly(a_graphql_entity_for(epic1), a_graphql_entity_for(epic2))
      end

      context 'when queried label names are empty' do
        let(:filter_params) { { filters: { or: { label_name: [] } } } }

        it 'returns all items' do
          post_graphql(pagination_query(filter_params), current_user: current_user)

          boards = graphql_data_at(*data_path, :nodes)
          expect(boards).to contain_exactly(
            a_graphql_entity_for(epic1), a_graphql_entity_for(epic2),
            a_graphql_entity_for(epic3))
        end
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(or_issuable_queries: false)
        end

        it 'does not add any filter' do
          post_graphql(pagination_query(filter_params), current_user: current_user)

          boards = graphql_data_at(*data_path, :nodes)
          expect(boards).to contain_exactly(
            a_graphql_entity_for(epic1), a_graphql_entity_for(epic2),
            a_graphql_entity_for(epic3))
        end
      end
    end

    context 'when using OR author filter' do
      let(:filter_params) { { filters: { or: { author_username: [epic1.author.username, epic2.author.username] } } } }

      it 'finds only epics matching at least one of the labels' do
        post_graphql(pagination_query(filter_params), current_user: current_user)

        boards = graphql_data_at(*data_path, :nodes)
        expect(boards).to contain_exactly(a_graphql_entity_for(epic1), a_graphql_entity_for(epic2))
      end

      context 'when queried label names are empty' do
        let(:filter_params) { { filters: { or: { author_username: [] } } } }

        it 'returns all items' do
          post_graphql(pagination_query(filter_params), current_user: current_user)

          boards = graphql_data_at(*data_path, :nodes)
          expect(boards).to contain_exactly(
            a_graphql_entity_for(epic1), a_graphql_entity_for(epic2),
            a_graphql_entity_for(epic3))
        end
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(or_issuable_queries: false)
        end

        it 'does not add any filter' do
          post_graphql(pagination_query(filter_params), current_user: current_user)

          boards = graphql_data_at(*data_path, :nodes)
          expect(boards).to contain_exactly(
            a_graphql_entity_for(epic1), a_graphql_entity_for(epic2),
            a_graphql_entity_for(epic3))
        end
      end
    end
  end
end
