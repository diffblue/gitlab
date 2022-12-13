# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Boards, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:board_parent) { create(:project, :public, group: group ) }
  let_it_be(:milestone) { create(:milestone, project: board_parent) }
  let_it_be(:board) { create(:board, project: board_parent, milestone: milestone, assignee: user) }

  before_all do
    group.add_maintainer(user)
  end

  it_behaves_like 'multiple and scoped issue boards', "/projects/:id/boards"

  before do
    stub_licensed_features(swimlanes: true)
  end

  describe 'POST /projects/:id/boards/:board_id/lists' do
    let(:url) { "/projects/#{board_parent.id}/boards/#{board.id}/lists" }

    it_behaves_like 'milestone board list'
    it_behaves_like 'assignee board list'
    it_behaves_like 'iteration board list' do
      let_it_be(:iteration) { create(:iteration, iterations_cadence: create(:iterations_cadence, group: group)) }
    end
  end

  context 'GET /projects/:id/boards/:board_id with special milestones' do
    let(:url) { "/projects/#{board_parent.id}/boards/#{board.id}" }

    it 'returns board with Upcoming milestone' do
      board.update!(milestone_id: Milestone::Upcoming.id)

      get api(url, user)

      expect(json_response["milestone"]["title"]).to eq(Milestone::Upcoming.title)
    end

    it 'returns board with Started milestone' do
      board.update!(milestone_id: Milestone::Started.id)

      get api(url, user)

      expect(json_response["milestone"]["title"]).to eq(Milestone::Started.title)
    end
  end

  describe 'GET /projects/:id/boards/:board_id/lists with max_issue_count' do
    let(:url) { "/projects/#{board_parent.id}/boards/#{board.id}/lists" }

    let!(:list) { create(:list, board: board) }

    context 'with WIP limits license' do
      before do
        get api(url, user)
      end

      it 'includes max_issue_count' do
        all_lists_in_response(include: 'max_issue_count')
      end

      it 'includes max_issue_weight' do
        all_lists_in_response(include: 'max_issue_weight')
      end

      it 'includes limit_metric' do
        all_lists_in_response(include: 'limit_metric')
      end
    end

    context 'without WIP limits license' do
      before do
        stub_licensed_features(wip_limits: false)

        get api(url, user)
      end

      it 'does not include max_issue_weight' do
        all_lists_in_response(do_not_include: 'max_issue_weight')
      end

      it 'does not include max_issue_count' do
        all_lists_in_response(do_not_include: 'max_issue_count')
      end

      it 'does not include limit_metric' do
        all_lists_in_response(do_not_include: 'limit_metric')
      end
    end

    def all_lists_in_response(params)
      expect(json_response).not_to be_empty

      if params.key?(:include)
        expect(json_response).to all(include(params[:include]))
      elsif params.key?(:do_not_include)
        expect(json_response.none? { |list_response| list_response.include?(params[:do_not_include]) }).to be_truthy
      end
    end
  end
end
