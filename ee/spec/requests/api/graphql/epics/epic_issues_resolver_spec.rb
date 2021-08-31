# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting epic issues information' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:project) { create(:project, group: group) }

  before_all do
    group.add_maintainer(user)
  end

  before do
    stub_licensed_features(epics: true)
  end

  context 'when toggling performance_roadmap feature flag' do
    let_it_be(:epic) { create(:epic, group: group, state: 'opened') }
    let_it_be(:issue1) { create(:issue, project: project) }
    let_it_be(:issue2) { create(:issue, project: project) }

    let(:query) do
      epic_issues_query(epic)
    end

    before_all do
      create(:epic_issue, epic: epic, issue: issue1)
      create(:epic_issue, epic: epic, issue: issue2)
    end

    def epic_issues_query(epic)
      epic_issues_fragment = <<~EPIC_ISSUE
        issues {
          nodes {
            id
          }
        }
      EPIC_ISSUE

      graphql_query_for(
        :group,
        { 'fullPath' => epic.group.full_path },
        query_graphql_field(
          'epic', { iid: epic.iid },
          epic_issues_fragment
        )
      )
    end

    def epic_issues_count
      graphql_data_at(:group, :epic, :issues, :nodes).count
    end

    it 'returns epics with max page based on feature flag status' do
      stub_const('SetsMaxPageSize::DEPRECATED_MAX_PAGE_SIZE', 1)

      post_graphql(epic_issues_query(epic), current_user: user)
      expect(epic_issues_count).to eq(2)

      stub_feature_flags(performance_roadmap: false)
      post_graphql(epic_issues_query(epic), current_user: user)
      expect(epic_issues_count).to eq(1)

      stub_feature_flags(performance_roadmap: true)
      post_graphql(epic_issues_query(epic), current_user: user)
      expect(epic_issues_count).to eq(2)
    end
  end
end
