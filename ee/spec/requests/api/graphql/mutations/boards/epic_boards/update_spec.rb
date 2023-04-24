# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::EpicBoards::Update, feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:board) { create(:epic_board, group: group, name: 'orig name') }

  let(:name) { 'board name' }
  let(:mutation) { graphql_mutation(:epic_board_update, params) }
  let(:label) { create(:group_label, group: group) }

  let(:params) do
    { id: board.to_global_id.to_s, name: 'foo', hide_backlog_list: true, labels: [label.name], display_colors: false }
  end

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  def mutation_response
    graphql_mutation_response(:epic_board_update)
  end

  before do
    stub_licensed_features(epics: true, scoped_issue_board: true)
  end

  context 'when the user does not have permission' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when the user has permission' do
    before do
      group.add_developer(current_user)
    end

    it 'returns the updated board' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response).to have_key('epicBoard')
      expect(mutation_response['epicBoard']['name']).to eq(params[:name])
      expect(mutation_response['epicBoard']['hideBacklogList']).to eq(params[:hide_backlog_list])
      expect(mutation_response['epicBoard']['displayColors']).to eq(params[:display_colors])
      expect(mutation_response['epicBoard']['labels']['count']).to eq(1)
    end

    context 'when epic_color_highlight flag is disabled' do
      before do
        stub_feature_flags(epic_color_highlight: false)
      end

      it 'ignores displayColors argument' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response).to have_key('epicBoard')
        expect(mutation_response['epicBoard']['displayColors']).to eq(true)
      end
    end

    context 'when update fails' do
      let(:params) { { id: board.to_global_id.to_s, name: 'x' * 256 } }

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response).to have_key('epicBoard')
        expect(mutation_response['epicBoard']['name']).to eq('orig name')
        expect(mutation_response['errors'].first).to eq('Name is too long (maximum is 255 characters)')
      end
    end
  end
end
