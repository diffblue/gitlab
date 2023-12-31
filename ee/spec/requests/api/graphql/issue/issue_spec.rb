# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.issue(id)', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:epic) { create(:epic, :confidential, group: group) }

  let(:issue) { create(:issue, :confidential, project: project, epic: epic) }
  let(:current_user) { create(:user) }
  let(:issue_params) { { 'id' => global_id_of(issue) } }
  let(:issue_data) { graphql_data['issue'] }
  let(:issue_fields) { ['hasEpic', 'epic { id }'] }

  let(:query) do
    graphql_query_for('issue', issue_params, issue_fields)
  end

  before do
    stub_licensed_features(epics: true)
  end

  context 'when user has no access to the epic' do
    before do
      project.add_developer(current_user)
    end

    context 'when there is an epic' do
      it 'returns null for epic and hasEpic is `true`' do
        post_graphql(query, current_user: current_user)

        expect(issue_data['hasEpic']).to eq(true)
        expect(issue_data['epic']).to be_nil
      end
    end

    context 'when there is no epic' do
      let_it_be(:epic) { nil }

      it 'returns null for epic and hasEpic is `false`' do
        post_graphql(query, current_user: current_user)

        expect(issue_data['hasEpic']).to eq(false)
        expect(issue_data['epic']).to be_nil
      end
    end
  end

  context 'when user has access to the epic' do
    before do
      group.add_developer(current_user)
    end

    it 'returns epic and hasEpic is `true`' do
      post_graphql(query, current_user: current_user)

      expect(issue_data['hasEpic']).to eq(true)
      expect(issue_data['epic']).to be_present
    end
  end

  context 'when issue has a parent link' do
    let_it_be(:work_item_issue) { create(:work_item, :issue, project: project) }
    let_it_be(:issue) { Issue.find(work_item_issue.id) }
    let(:issue_fields) { ['hasParent'] }

    it 'returns hasParent as `true`' do
      project.add_developer(current_user)
      create(:parent_link, work_item: work_item_issue, work_item_parent: create(:work_item, :epic, project: project))
      post_graphql(query, current_user: current_user)

      expect(issue_data['hasParent']).to eq(true)
    end
  end
end
