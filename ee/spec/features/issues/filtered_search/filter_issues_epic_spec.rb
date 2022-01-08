# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Filter issues by epic', :js do
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

  let(:filter_dropdown) { find("#js-dropdown-epic .filter-dropdown") }

  before do
    stub_licensed_features(epics: true)
    group.add_maintainer(user)

    sign_in(user)
  end

  shared_examples 'filter issues by epic' do
    it 'filters issues by epic' do
      input_filtered_search("epic:=&#{epic1.id}")

      expect_issues_list_count(1)
    end

    it 'filters issues by negated epic' do
      input_filtered_search("epic:!=&#{epic1.id}")

      expect_issues_list_count(2)
    end

    it 'shows epics in the filtered search dropdown' do
      input_filtered_search('epic:=', submit: false, extra_space: false)

      expect_filtered_search_dropdown_results(filter_dropdown, 2)
    end

    it 'shows correct filtered search epic token value' do
      input_filtered_search('epic:=', submit: false, extra_space: false)
      click_on epic1.title

      expect(find('.filtered-search-token .value').text).to eq("\"#{epic1.title}\"::&#{epic1.id}")
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
