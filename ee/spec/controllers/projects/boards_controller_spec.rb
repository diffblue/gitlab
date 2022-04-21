# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BoardsController do
  let(:project) { create(:project, namespace: create(:namespace, :with_namespace_settings)) }
  let(:user)    { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET index' do
    let(:parent) { project }

    it 'returns a list of project boards including milestones' do
      create(:board, project: project, milestone: create(:milestone, project: project))
      create(:board, project: project, milestone_id: Milestone::Upcoming.id)

      list_boards

      expect(response).to match_response_schema('boards')
      expect(json_response.length).to eq 2
    end

    it_behaves_like 'redirects to last visited board'

    it_behaves_like 'pushes wip limits to frontend' do
      let(:parent) { project }
      let(:params) { { namespace_id: parent.namespace, project_id: parent } }
    end
  end

  describe 'GET recent' do
    let(:parent) { project }

    it_behaves_like 'returns recently visited boards'

    context 'unauthenticated' do
      it 'returns a 302' do
        sign_out(user)

        list_boards(recent: true)

        expect(response).to have_gitlab_http_status(:found)
      end
    end
  end

  describe 'GET show' do
    let(:parent) { project }

    it_behaves_like 'multiple issue boards show'
  end

  describe 'POST create' do
    context 'with the multiple issue boards available' do
      context 'with valid params' do
        let(:user) { create(:user) }
        let(:milestone) { create(:milestone, project: project) }
        let(:label) { create(:label) }
        let(:project_label) { create(:label, project: project) }

        let(:create_params) do
          { name: 'Backend',
            weight: 1,
            milestone_id: milestone.id,
            assignee_id: user.id,
            label_ids: [label.id, project_label.id] }
        end

        it 'returns a successful 200 response' do
          create_board create_params

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'returns the created board' do
          create_board create_params

          expect(response).to match_response_schema('board')
        end

        it 'valid board is created' do
          create_board create_params

          board = Board.first

          expect(Board.count).to eq(1)
          expect(board).to have_attributes(create_params.except(:assignee_id, :label_ids))
          expect(board.labels).to eq([project_label])
          expect(board.assignee).to eq(user)
        end
      end

      context 'with invalid params' do
        it 'returns an unprocessable entity 422 response' do
          create_board name: nil

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end

      context 'with unauthorized user' do
        before do
          expect(Ability).to receive(:allowed?).with(user, :log_in, :global).and_call_original
          allow(Ability).to receive(:allowed?).with(user, :read_project, project).and_return(true)
          allow(Ability).to receive(:allowed?).with(user, :admin_issue_board, project).and_return(false)
        end

        it 'returns a not found 404 response' do
          create_board name: 'Backend'

          expect(response.media_type).to eq 'application/json'
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    def create_board(board_params)
      post :create, params: {
                      namespace_id: project.namespace.to_param,
                      project_id: project.to_param,
                      board: board_params
                    },
                    format: :json
    end
  end

  describe 'PATCH update' do
    let(:board) { create(:board, project: project, name: 'Backend') }
    let(:user) { create(:user) }
    let(:milestone) { create(:milestone, project: project) }
    let(:label) { create(:label) }
    let(:project_label) { create(:label, project: project) }

    let(:update_params) do
      { name: 'Frontend',
        weight: 1,
        milestone_id: milestone.id,
        assignee_id: user.id,
        label_ids: [label.id, project_label.id] }
    end

    context 'with valid params' do
      it 'returns a successful 200 response' do
        update_board board, update_params

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns the updated board' do
        update_board board, update_params

        expect(response).to match_response_schema('board')
      end

      it 'updates board with valid params' do
        update_board board, update_params

        expect(board.reload).to have_attributes(update_params.except(:assignee_id, :label_ids))
        expect(board.labels).to eq([project_label])
        expect(board.assignee).to eq(user)
      end
    end

    context 'with invalid params' do
      it 'returns an unprocessable entity 422 response' do
        update_board board, name: nil

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'with invalid board id' do
      it 'returns a not found 404 response' do
        update_board non_existing_record_id, name: nil

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with unauthorized user' do
      before do
        expect(Ability).to receive(:allowed?).with(user, :log_in, :global).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :read_project, project).and_return(true)
        allow(Ability).to receive(:allowed?).with(user, :admin_issue_board, project).and_return(false)
      end

      it 'returns a not found 404 response' do
        update_board board, update_params

        expect(response.media_type).to eq 'application/json'
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def update_board(board, update_params)
      patch :update, params: {
                       namespace_id: project.namespace.to_param,
                       project_id: project.to_param,
                       id: board.to_param,
                       board: update_params
                     },
                     format: :json
    end
  end

  describe 'DELETE destroy' do
    let!(:boards) { create_pair(:board, project: project) }
    let(:board)   { project.boards.first }

    context 'with valid board id' do
      it 'redirects to the issue boards page' do
        remove_board board: board

        expect(response).to redirect_to(project_boards_path(project))
      end

      it 'removes board from project' do
        expect { remove_board board: board }.to change(project.boards, :size).by(-1)
      end
    end

    context 'with invalid board id' do
      it 'returns a not found 404 response' do
        remove_board board: non_existing_record_id

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with unauthorized user' do
      before do
        expect(Ability).to receive(:allowed?).with(user, :log_in, :global).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :read_project, project).and_return(true)
        allow(Ability).to receive(:allowed?).with(user, :admin_issue_board, project).and_return(false)
      end

      it 'returns a not found 404 response' do
        remove_board board: board

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def remove_board(board:)
      delete :destroy, params: {
                         namespace_id: project.namespace.to_param,
                         project_id: project.to_param,
                         id: board.to_param
                       },
                       format: :html
    end
  end
end
