# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Filter issues by epic', :js, feature_category: :team_planning do
  include FilteredSearchHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue1) { create(:issue, project: project) }
  let_it_be(:issue2) { create(:issue, project: project) }
  let_it_be(:issue3) { create(:issue, project: project) }
  let_it_be(:epic1) { create(:epic, group: group) }
  let_it_be(:epic2) { create(:epic, group: group) }
  let_it_be(:epic_issue1) { create(:epic_issue, issue: issue1, epic: epic1) }
  let_it_be(:epic_issue2) { create(:epic_issue, issue: issue2, epic: epic2) }
  let_it_be(:epic_issue3) { create(:epic_issue, issue: issue3, epic: epic2) }

  before do
    stub_feature_flags(or_issuable_queries: false)
    stub_licensed_features(epics: true)
    group.add_maintainer(user)

    sign_in(user)
  end

  shared_examples 'filter issues by epic' do
    it 'filters issues by epic' do
      select_tokens 'Epic', '=', epic1.title, submit: true

      expect_issues_list_count(1)
    end

    it 'filters issues by negated epic' do
      select_tokens 'Epic', '!=', epic1.title, submit: true

      expect_issues_list_count(2)
    end

    it 'shows epics in the filtered search dropdown' do
      select_tokens 'Epic', '='

      # Expect None, Any, My title 5, My title 4
      expect_suggestion_count 4
    end

    it 'shows correct filtered search epic token value' do
      select_tokens 'Epic', '='
      click_on epic1.title

      expect_epic_token "&#{epic1.id}::#{epic1.title}"
    end
  end

  context 'when group issues list page' do
    before do
      visit issues_group_path(group)
    end

    it_behaves_like 'filter issues by epic'
  end

  context 'when project issues list page' do
    before do
      visit project_issues_path(project)
    end

    it_behaves_like 'filter issues by epic'
  end
end
