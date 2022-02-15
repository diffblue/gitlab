# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'group epic roadmap', :js do
  include FilteredSearchHelpers
  include MobileHelpers

  let(:user) { create(:user) }
  let(:user_dev) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:subgroup) { create(:group, :public, parent: group) }
  let(:project) { create(:project, :public, group: group) }

  let!(:bug_label) { create(:group_label, group: group, title: 'Bug') }
  let!(:critical_label) { create(:group_label, group: group, title: 'Critical') }

  def search_for_label(label)
    page.within('.vue-filtered-search-bar-container .gl-search-box-by-click') do
      page.find('input.gl-filtered-search-term-input').click
      click_link 'Label'
      page.first('.gl-filtered-search-suggestion-list .gl-filtered-search-suggestion').click # Select `=` operator
      wait_for_requests
      page.find('.gl-filtered-search-suggestion-list .gl-filtered-search-suggestion', text: bug_label.title).click
    end
    page.find('.gl-search-box-by-click-search-button').click
  end

  def expand_epic_at(index)
    expand_buttons = page.all("button[aria-label='Expand']")
    expand_buttons[index].click
    wait_for_requests
  end

  def toggle_sort_direction
    page.within('.vue-filtered-search-bar-container .sort-dropdown-container') do
      page.find("button[title^='Sort direction']").click
      wait_for_requests
    end
  end

  before do
    stub_licensed_features(epics: true)
    stub_feature_flags(unfiltered_epic_aggregates: false)

    sign_in(user)
  end

  context 'with roadmap_settings feature flag off' do
    let!(:epic_with_bug) { create(:labeled_epic, group: group, start_date: 10.days.ago, end_date: 1.day.ago, labels: [bug_label]) }
    let!(:epic_with_critical) { create(:labeled_epic, group: group, start_date: 20.days.ago, end_date: 2.days.ago, labels: [critical_label]) }
    let!(:closed_epic) { create(:epic, :closed, group: group, start_date: 20.days.ago, end_date: 2.days.ago) }
    let(:state_dropdown) { find('.dropdown-epics-state') }

    before do
      stub_feature_flags(roadmap_settings: false)

      visit group_roadmap_path(group)
      wait_for_requests
    end

    context 'roadmap daterange filtering' do
      def select_date_range(range_type)
        page.within('.epics-roadmap-filters') do
          page.find('[data-testid="daterange-dropdown"] button.dropdown-toggle').click
          click_button(range_type)
        end
      end

      it 'renders daterange filtering dropdown with "This quarter" selected by default no layout presets available', :aggregate_failures do
        page.within('.epics-roadmap-filters') do
          expect(page).to have_selector('[data-testid="daterange-dropdown"]')
          expect(page).not_to have_selector('.gl-segmented-control')
          expect(page.find('[data-testid="daterange-dropdown"] button.dropdown-toggle')).to have_content('This quarter')
        end
      end

      it 'selecting "This year" as daterange shows `Months` and `Weeks` layout presets', :aggregate_failures do
        select_date_range('This year')

        page.within('.epics-roadmap-filters') do
          expect(page).to have_selector('.gl-segmented-control')
          expect(page).to have_selector('input[value="MONTHS"]')
          expect(page).to have_selector('input[value="WEEKS"]')
        end
      end

      it 'selecting "Within 3 years" as daterange shows `Quarters`, `Months` and `Weeks` layout presets', :aggregate_failures do
        select_date_range('Within 3 years')

        page.within('.epics-roadmap-filters') do
          expect(page).to have_selector('.gl-segmented-control')
          expect(page).to have_selector('input[value="QUARTERS"]')
          expect(page).to have_selector('input[value="MONTHS"]')
          expect(page).to have_selector('input[value="WEEKS"]')
        end
      end
    end

    it 'renders the epics state dropdown' do
      page.within('.content-wrapper .content .epics-filters') do
        expect(page).to have_css('.dropdown-epics-state')
      end
    end

    describe 'roadmap page with epics state filter' do
      before do
        state_dropdown.find('.dropdown-toggle').click
      end

      it 'renders open epics only' do
        state_dropdown.find('button', text: 'Open epics').click

        page.within('.roadmap-container .epics-list-section') do
          expect(page).to have_selector('.epics-list-item .epic-title', count: 2)
        end
      end

      it 'renders closed epics only' do
        state_dropdown.find('button', text: 'Closed epics').click

        page.within('.roadmap-container .epics-list-section') do
          expect(page).to have_selector('.epics-list-item .epic-title', count: 1)
        end
      end
    end

    describe 'roadmap page with filter applied' do
      before do
        search_for_label(bug_label)
      end

      it 'keeps label filter when filtering by state' do
        state_dropdown.find('.dropdown-toggle').click
        state_dropdown.find('button', text: 'Open epics').click

        page.within('.roadmap-container .epics-list-section') do
          expect(page).to have_selector('.epics-list-item .epic-title', count: 1)
          expect(page).to have_content(epic_with_bug.title)
        end
      end
    end
  end

  context 'when epics exist for the group' do
    available_tokens = %w[Author Label Milestone Epic My-Reaction]
    available_sort_options = ['Start date', 'Due date']

    let!(:epic_with_bug) { create(:labeled_epic, group: group, start_date: 10.days.ago, end_date: 1.day.ago, labels: [bug_label]) }
    let!(:epic_with_critical) { create(:labeled_epic, group: group, start_date: 20.days.ago, end_date: 2.days.ago, labels: [critical_label]) }
    let!(:closed_epic) { create(:epic, :closed, group: group, start_date: 20.days.ago, end_date: 2.days.ago) }
    let!(:milestone) { create(:milestone, :with_dates, group: group, start_date: 10.days.ago, due_date: 1.day.ago) }
    let!(:milestone_subgroup) { create(:milestone, :with_dates, group: subgroup, start_date: 10.days.ago, due_date: 1.day.ago) }
    let!(:milestone_project) { create(:milestone, :with_dates, project: project, start_date: 10.days.ago, due_date: 1.day.ago) }
    let!(:milestone_project_2) { create(:milestone, :with_dates, project: project, start_date: 10.days.ago, due_date: 1.day.ago) }

    before do
      visit group_roadmap_path(group)
      wait_for_requests
    end

    describe 'roadmap page' do
      def open_settings_sidebar
        click_button 'Settings'
        expect(page).to have_selector('[data-testid="roadmap-settings"]')
      end

      context 'roadmap daterange filtering' do
        def select_date_range(range_type)
          open_settings_sidebar

          page.within('[data-testid="roadmap-settings"]') do
            page.find('[data-testid="daterange-dropdown"] button.dropdown-toggle').click
            click_button(range_type)
          end
        end

        it 'renders daterange filtering dropdown with "This quarter" selected by default no layout presets available', :aggregate_failures do
          open_settings_sidebar

          page.within('[data-testid="roadmap-settings"]') do
            expect(page).to have_selector('[data-testid="daterange-dropdown"]')
            expect(page).not_to have_selector('[data-testid="daterange-presets"]')
            expect(page.find('[data-testid="daterange-dropdown"] button.dropdown-toggle')).to have_content('This quarter')
          end
        end

        it 'selecting "This year" as daterange shows `Months` and `Weeks` layout presets', :aggregate_failures do
          select_date_range('This year')

          page.within('[data-testid="roadmap-settings"]') do
            expect(page).to have_selector('[data-testid="daterange-presets"]')
            expect(page).to have_selector('input[value="MONTHS"]')
            expect(page).to have_selector('input[value="WEEKS"]')
          end
        end

        it 'selecting "Within 3 years" as daterange shows `Quarters`, `Months` and `Weeks` layout presets', :aggregate_failures do
          select_date_range('Within 3 years')

          page.within('[data-testid="roadmap-settings"]') do
            expect(page).to have_selector('[data-testid="daterange-presets"]')
            expect(page).to have_selector('input[value="QUARTERS"]')
            expect(page).to have_selector('input[value="MONTHS"]')
            expect(page).to have_selector('input[value="WEEKS"]')
          end
        end
      end

      describe 'roadmap page with epics state filter' do
        def select_state(state)
          page.within('[data-testid="roadmap-epics-state"]') do
            choose state
          end
        end

        before do
          open_settings_sidebar
        end

        it 'renders open epics only' do
          select_state('Show open epics')

          page.within('.roadmap-container .epics-list-section') do
            expect(page).to have_selector('.epics-list-item .epic-title', count: 2)
          end
        end

        it 'renders closed epics only' do
          select_state('Show closed epics')

          page.within('.roadmap-container .epics-list-section') do
            expect(page).to have_selector('.epics-list-item .epic-title', count: 1)
          end
        end

        it 'saves last selected epic state', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/341827' do
          select_state('Show open epics')

          wait_for_all_requests
          visit group_roadmap_path(group)
          wait_for_requests

          page.within('.roadmap-container .epics-list-section') do
            expect(page).to have_selector('.epics-list-item .epic-title', count: 2)
          end
        end
      end

      describe 'roadmap milestones settings' do
        def select_milestones(milestones)
          page.within('[data-testid="roadmap-milestones-settings"]') do
            choose milestones
          end
        end

        def expect_milestones_count(count)
          page.within('.roadmap-container .milestones-list-section') do
            expect(page).to have_selector('.milestone-item-details', count: count)
          end
        end

        before do
          open_settings_sidebar
        end

        it 'renders milestones section' do
          page.within('.roadmap-container') do
            expect(page).to have_selector('.milestones-list-section')
          end
        end

        it 'renders milestones based on filter' do
          milestones_counts = {
            'Show all milestones' => 4,
            'Show group milestones' => 2, # group & subgroup
            'Show sub-group milestones' => 1,
            'Show project milestones' => 2
          }

          milestones_counts.each do |filter, count|
            select_milestones(filter)

            expect_milestones_count(count)
          end
        end

        it 'turns off milestones' do
          page.within('[data-testid="roadmap-milestones-settings"]') do
            click_button class: 'gl-toggle'
          end

          page.within('.roadmap-container') do
            expect(page).not_to have_selector('.milestones-list-section')
          end
        end
      end

      it 'renders the filtered search bar correctly' do
        page.within('.content-wrapper .content .epics-filters') do
          expect(page).to have_css('.vue-filtered-search-bar-container')
        end
      end

      it 'renders roadmap view' do
        page.within('.content-wrapper .content') do
          expect(page).to have_css('.roadmap-container')
        end
      end

      it 'renders all group epics within roadmap' do
        page.within('.roadmap-container .epics-list-section') do
          expect(page).to have_selector('.epics-list-item .epic-title', count: 3)
        end
      end

      it 'toggles settings sidebar on click settings button' do
        page.within('.content-wrapper .content') do
          expect(page).not_to have_selector('[data-testid="roadmap-sidebar"]')
          expect(page).to have_selector('[data-testid="settings-button"]')

          click_button 'Settings'
          expect(page).to have_selector('[data-testid="roadmap-settings"]')

          click_button 'Settings'
          expect(page).not_to have_selector('[data-testid="roadmap-settings"]')
        end
      end
    end

    describe 'roadmap page with filter applied' do
      before do
        search_for_label(bug_label)
      end

      it 'renders filtered search bar with applied filter token' do
        expect_vue_tokens([label_token(bug_label.title)])
      end

      it 'renders roadmap view with matching epic' do
        page.within('.roadmap-container .epics-list-section') do
          expect(page).to have_selector('.epics-list-item .epic-title', count: 1)
          expect(page).to have_content(epic_with_bug.title)
        end
      end
    end

    describe 'roadmap page with sort order applied' do
      let!(:parent_epic1) { create(:epic, title: 'Parent Epic 1', group: group, start_date: 19.days.ago, end_date: 9.days.ago) }
      let!(:child_epic1) { create(:epic, title: 'Child Epic 1', group: group, parent_id: parent_epic1.id, start_date: 18.days.ago, end_date: 4.days.ago) }
      let!(:child_epic2) { create(:epic, title: 'Child Epic 2', group: group, parent_id: parent_epic1.id, start_date: 17.days.ago, end_date: 6.days.ago) }

      let!(:parent_epic2) { create(:epic, title: 'Parent Epic 2', group: group, start_date: 14.days.ago, end_date: 4.days.ago) }
      let!(:child_epic3) { create(:epic, title: 'Child Epic 3', group: group, parent_id: parent_epic2.id, end_date: 4.days.ago) }
      let!(:child_epic4) { create(:epic, title: 'Child Epic 4', group: group, parent_id: parent_epic2.id, end_date: 6.days.ago) }

      before do
        visit group_roadmap_path(group)
        wait_for_requests
      end

      it 'renders the epics in expected order' do
        page.within('.roadmap-container .epics-list-section') do
          expect(page).to have_selector('.epics-list-item .epic-title', count: 5)
          epic_titles = page.all('.epics-list-item .epic-title').collect(&:text)

          expect(epic_titles).to eq([
            closed_epic.title,
            epic_with_critical.title,
            parent_epic1.title,
            parent_epic2.title,
            epic_with_bug.title
          ])

          expand_epic_at(0)

          expect(page).to have_selector('.epics-list-item .epic-title', count: 7)
          epic_titles = page.all('.epics-list-item .epic-title').collect(&:text)

          expect(epic_titles).to eq([
            closed_epic.title,
            epic_with_critical.title,
            parent_epic1.title,
            child_epic1.title,
            child_epic2.title,
            parent_epic2.title,
            epic_with_bug.title
          ])
        end

        toggle_sort_direction

        page.within('.roadmap-container .epics-list-section') do
          expect(page).to have_selector('.epics-list-item .epic-title', count: 5)
          epic_titles = page.all('.epics-list-item .epic-title').collect(&:text)

          expect(epic_titles).to eq([
            epic_with_bug.title,
            parent_epic2.title,
            parent_epic1.title,
            closed_epic.title,
            epic_with_critical.title
          ])

          expand_epic_at(1)

          expect(page).to have_selector('.epics-list-item .epic-title', count: 7)
          epic_titles = page.all('.epics-list-item .epic-title').collect(&:text)

          expect(epic_titles).to eq([
            epic_with_bug.title,
            parent_epic2.title,
            parent_epic1.title,
            child_epic2.title,
            child_epic1.title,
            closed_epic.title,
            epic_with_critical.title
          ])
        end
      end
    end

    describe 'filtered search' do
      let!(:epic1) { create(:epic, group: group, end_date: 10.days.ago) }
      let!(:epic2) { create(:epic, group: group, start_date: 2.days.ago) }
      let!(:award_emoji_star) { create(:award_emoji, name: 'star', user: user, awardable: epic1) }

      before do
        group.add_developer(user_dev)
        visit group_roadmap_path(group)
        wait_for_requests
      end

      it_behaves_like 'filtered search bar', available_tokens, available_sort_options
    end

    describe 'that is a sub-group' do
      let!(:subgroup) { create(:group, parent: group, name: 'subgroup') }
      let!(:sub_epic1) { create(:epic, group: subgroup, end_date: 10.days.ago) }
      let!(:sub_epic2) { create(:epic, group: subgroup, start_date: 2.days.ago) }
      let!(:award_emoji_star) { create(:award_emoji, name: 'star', user: user, awardable: sub_epic1) }

      before do
        subgroup.add_developer(user_dev)
        visit group_roadmap_path(subgroup)
        wait_for_requests
      end

      it_behaves_like 'filtered search bar', available_tokens, available_sort_options
    end
  end

  context 'when no epics exist for the group' do
    before do
      visit group_roadmap_path(group)
      wait_for_requests
    end

    describe 'roadmap page' do
      it 'shows empty state page' do
        page.within('.empty-state') do
          expect(page).to have_content('The roadmap shows the progress of your epics along a timeline')
        end
      end
    end
  end
end
