# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'get list of epic boards', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:board) { create(:epic_board, group: group) }
  let_it_be(:list1) { create(:epic_list, epic_board: board) }
  let_it_be(:list2) { create(:epic_list, epic_board: board, list_type: :closed) }
  let_it_be(:list3) { create(:epic_list, epic_board: board, list_type: :backlog) }

  let(:fields) { all_graphql_fields_for('epic_lists'.classify) }

  def pagination_query(params = {})
    graphql_query_for(:group, { full_path: group.full_path },
      <<~BOARDS
        epicBoard(id: "#{board.to_global_id}") {
          #{query_nodes(:lists, fields, include_pagination_info: true, args: params)}
        }
      BOARDS
    )
  end

  before do
    stub_licensed_features(epics: true)
  end

  context 'when the user does not have access to the epic board group' do
    it 'returns nil group' do
      post_graphql(pagination_query, current_user: current_user)

      expect(graphql_data['group']).to be_nil
    end
  end

  context 'when user can access the epic board group' do
    before do
      group.add_developer(current_user)
    end

    describe 'sorting and pagination' do
      let(:data_path) { [:group, :epicBoard, :lists] }
      let(:all_records) { [list3.to_global_id.to_s, list1.to_global_id.to_s, list2.to_global_id.to_s] }

      def pagination_results_data(nodes)
        nodes.map { |list| list['id'] }
      end

      it_behaves_like 'sorted paginated query' do
        include_context 'no sort argument'

        let(:first_param) { 2 }
      end
    end

    it 'avoids N+1 queries' do
      list1.update_preferences_for(current_user, collapsed: true)

      control = ActiveRecord::QueryRecorder.new { post_graphql(pagination_query, current_user: current_user) }

      list2.update_preferences_for(current_user, collapsed: true)

      expect { post_graphql(pagination_query, current_user: current_user) }.not_to exceed_query_limit(control)
    end

    describe 'field values', :sidekiq_inline do
      let_it_be(:other_user) { create(:user) }

      it 'returns the correct values for collapsed' do
        list1.update_preferences_for(current_user, collapsed: true)
        list1.update_preferences_for(other_user, collapsed: false)

        post_graphql(pagination_query, current_user: current_user)

        # ordered by list_type then position - backlog first and closed last.
        expect(list_nodes).to match [
          a_graphql_entity_for(list3, collapsed: false),
          a_graphql_entity_for(list1, collapsed: true),
          a_graphql_entity_for(list2, collapsed: false)
        ]
      end

      it 'returns the correct metadata values' do
        label1 = create(:group_label, group: group)
        label2 = create(:group_label, group: group)
        # Epics in backlog, the list which is returned first. The first epic
        # should be ignored because it doesn't have the label by which we are
        # filtering.
        create(:labeled_epic, group: group)
        create(:labeled_epic, group: group, labels: [label1], confidential: true)
        create(:labeled_epic, group: group, labels: [label2], confidential: true)
        epic_with_issue = create(:labeled_epic, group: group, labels: [label1])

        create(:issue, project: project, epic: epic_with_issue, weight: 3)
        create(:issue, project: project, epic: epic_with_issue, weight: 4)

        params = { epicFilters: { or: { labelName: [label1.title, label2.title] }, confidential: false } }
        post_graphql(pagination_query(params), current_user: current_user)

        expect(list_nodes).to match [
          a_hash_including('epicsCount' => 1, 'metadata' => { 'epicsCount' => 1, 'totalWeight' => 7 }),
          a_hash_including('epicsCount' => 0, 'metadata' => { 'epicsCount' => 0, 'totalWeight' => 0 }),
          a_hash_including('epicsCount' => 0, 'metadata' => { 'epicsCount' => 0, 'totalWeight' => 0 })
        ]
      end

      context 'when totalWeight not requested' do
        let(:fields) { "metadata { epicsCount }" }

        it 'does not required the value from the service' do
          post_graphql(pagination_query, current_user: current_user)

          expect(list_nodes('metadata').first.keys).to match_array(['epicsCount'])
        end
      end
    end
  end

  def assert_field_value(field, expected_value)
    expect(list_nodes(field)).to eq(expected_value)
  end

  def list_nodes(*fields)
    graphql_dig_at(graphql_data, 'group', 'epicBoard', 'lists', 'nodes', *fields)
  end
end
