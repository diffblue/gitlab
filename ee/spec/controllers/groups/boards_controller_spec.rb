# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::BoardsController, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  before_all do
    group.add_maintainer(user)
  end

  before do
    allow(Ability).to receive(:allowed?).and_call_original
    sign_in(user)
    stub_licensed_features(multiple_group_issue_boards: true)
  end

  describe 'GET index' do
    let_it_be(:boards) { create_list(:board, 3, resource_parent: group) }

    before_all do
      visit_board(boards[2], Time.current + 1.minute)
      visit_board(boards[0], Time.current + 2.minutes)
      visit_board(boards[1], Time.current + 5.minutes)
    end

    context 'when multiple boards are disabled' do
      before do
        stub_licensed_features(multiple_group_issue_boards: false)
      end

      it 'renders first board' do
        list_boards

        expect(response).to render_template :index
        expect(response.media_type).to eq 'text/html'
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when multiple boards are enabled' do
      before do
        stub_licensed_features(multiple_group_issue_boards: true)
      end

      it 'redirects to latest visited board' do
        list_boards

        expect(response).to redirect_to(group_board_path(group_id: group, id: boards[1].id))
      end
    end

    def visit_board(board, time)
      create(:board_group_recent_visit, group: group, board: board, user: user, updated_at: time)
    end

    def list_boards
      get :index, params: { group_id: group }
    end

    it_behaves_like 'pushes wip limits to frontend' do
      let(:params) { { group_id: group } }
      let(:parent) { group }
    end
  end

  describe 'GET show' do
    let_it_be(:board1) { create(:board, resource_parent: group, name: 'b') }
    let_it_be(:board2) { create(:board, resource_parent: group, name: 'a') }

    context 'when multiple issue boards is enabled' do
      it 'lets user view board1' do
        show(board1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:board)).to eq(board1)
      end

      it 'lets user view board2' do
        show(board2)

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:board)).to eq(board2)
      end
    end

    context 'when multiple issue boards is disabled' do
      before do
        stub_licensed_features(multiple_group_issue_boards: false)
      end

      it 'let user view the default shown board' do
        show(board2)

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:board)).to eq(board2)
      end

      it 'renders 404 when project board is not the default' do
        show(board1)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def show(board)
      get :show, params: { id: board.to_param, group_id: group }
    end
  end
end
