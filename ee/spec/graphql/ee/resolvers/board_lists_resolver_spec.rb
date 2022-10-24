# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::BoardListsResolver do
  include GraphqlHelpers

  let_it_be(:user)          { create(:user) }
  let_it_be(:project)       { create(:project, creator_id: user.id, namespace: user.namespace) }
  let_it_be(:group)         { create(:group, :private) }
  let_it_be(:project_milestone) { create(:milestone, project: project) }
  let_it_be(:group_milestone)   { create(:milestone, group: group) }

  before do
    stub_licensed_features(board_assignee_lists: true, board_milestone_lists: true)
  end

  shared_examples_for 'group and project board lists resolver' do
    let(:board) { create(:board, resource_parent: board_parent) }
    let!(:user_list) { create(:user_list, board: board, user: user) }
    let!(:milestone_list) { create(:milestone_list, board: board, milestone: milestone) }

    before do
      board_parent.add_developer(user)
    end

    it 'returns a list of board lists' do
      lists = resolve_board_lists

      expect(lists.count).to eq 3
      expect(lists.map(&:list_type)).to eq %w(closed assignee milestone)
    end
  end

  describe '#resolve' do
    context 'when project boards' do
      let(:board_parent) { project }
      let(:milestone)    { project_milestone }

      it_behaves_like 'group and project board lists resolver'
    end

    context 'when group boards' do
      let(:board_parent) { group }
      let(:milestone)    { group_milestone }

      it_behaves_like 'group and project board lists resolver'
    end
  end

  def resolve_board_lists(args: {}, current_user: user)
    context = GraphQL::Query::Context.new(
      query: query_double(schema: nil),
      values: { current_user: current_user },
      object: nil
    )

    resolve(described_class, obj: board, args: args, ctx: context)
  end
end
