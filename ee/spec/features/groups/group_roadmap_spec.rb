# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'group epic roadmap', :js, feature_category: :portfolio_management do
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
      page.find('[data-testid="filtered-search-term-input"]').click
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

  before do
    stub_licensed_features(epics: true)

    sign_in(user)
  end

  context 'when epics exist for the group' do
    let(:end_of_quarter) { Date.today.end_of_quarter }
    let!(:epic_with_bug) { create(:labeled_epic, group: group, start_date: end_of_quarter - 10.days, end_date: end_of_quarter - 1.day, labels: [bug_label]) }
    let!(:epic_with_critical) { create(:labeled_epic, group: group, start_date: end_of_quarter - 20.days, end_date: end_of_quarter - 2.days, labels: [critical_label]) }
    let!(:closed_epic) { create(:epic, :closed, group: group, start_date: end_of_quarter - 20.days, end_date: end_of_quarter - 2.days) }
    let!(:sub_epic) { create(:epic, group: group, parent: epic_with_bug) }
    let!(:sub_epic2) { create(:epic, group: group, parent: sub_epic, start_date: end_of_quarter - 20.days, end_date: end_of_quarter - 2.days) }
    let!(:milestone) { create(:milestone, :with_dates, group: group, start_date: end_of_quarter - 10.days, due_date: end_of_quarter - 1.day) }
    let!(:milestone_subgroup) { create(:milestone, :with_dates, group: subgroup, start_date: end_of_quarter - 10.days, due_date: end_of_quarter - 1.day) }
    let!(:milestone_project) { create(:milestone, :with_dates, project: project, start_date: end_of_quarter - 10.days, due_date: end_of_quarter - 1.day) }
    let!(:milestone_project_2) { create(:milestone, :with_dates, project: project, start_date: end_of_quarter - 10.days, due_date: end_of_quarter - 1.day) }

    available_tokens = %w[Author Label Milestone Epic My-Reaction]
    available_sort_options = ['Start date', 'Due date']

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

        it 'renders top level epics only' do
          page.within('.roadmap-container .epics-list-section') do
            expect(page).to have_content(epic_with_bug.title)
            expect(page).not_to have_content(sub_epic.title)
            expect(page).not_to have_content(sub_epic2.title)
          end
        end
      end

      describe 'roadmap with epics progress tracking' do
        def wait_for_epics(count, icon)
          page.within('.roadmap-container .epics-list-section') do
            expect(page).to have_selector('.epic-bar-progress', count: count)
            expect(page).to have_selector("[data-testid='#{icon}']", count: count)
          end
        end

        before do
          open_settings_sidebar
        end

        it 'renders progress bar using weight', :aggregate_failures do
          choose 'Use issue weight'

          wait_for_epics(3, "weight-icon")
        end

        it 'renders progress bar issue count', :aggregate_failures do
          choose 'Use issue count'

          wait_for_epics(3, "issue-closed-icon")
        end

        it 'turns off progress tracking', :aggregate_failures do
          page.within('[data-testid="roadmap-progress-tracking"]') do
            click_button class: 'gl-toggle'
          end

          page.within('.roadmap-container .epics-list-section') do
            expect(page).not_to have_selector('.epic-bar-progress')
            expect(page).not_to have_selector('[data-testid="issue-closed-icon"]')
            expect(page).not_to have_selector('[data-testid="weight-icon"]')
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
            'Show group milestones' => 1,
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

      describe 'roadmap labels settings' do
        it 'does not render labels by default' do
          page.within('.roadmap-container') do
            expect(page).not_to have_selector('[data-testid="epic-labels"]')
          end
        end

        it 'turns on labels' do
          open_settings_sidebar

          page.within('[data-testid="roadmap-labels-settings"]') do
            click_button class: 'gl-toggle'
          end

          page.within('.roadmap-container') do
            expect(page).to have_selector('[data-testid="epic-labels"]')
          end
        end
      end

      it 'renders the filtered search bar correctly' do
        page.within('.content-wrapper .content .epics-filters') do
          expect(page).to have_css('.vue-filtered-search-bar-container')
        end
      end

      it 'filters by child epic', :aggregate_failures, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/391611' do
        page.find('[data-testid="filtered-search-term-input"]').click
        click_link 'Epic'
        click_link sub_epic.title
        click_button 'Search'

        wait_for_requests

        expect(page).to have_content(sub_epic.title)
        expect(page).not_to have_content(epic_with_bug.title)
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
      let!(:parent_epic1) { create(:epic, title: 'Parent Epic 1', group: group, start_date: end_of_quarter - 19.days, end_date: end_of_quarter - 9.days) }
      let!(:child_epic1) { create(:epic, title: 'Child Epic 1', group: group, parent_id: parent_epic1.id, start_date: end_of_quarter - 18.days, end_date: end_of_quarter - 4.days) }
      let!(:child_epic2) { create(:epic, title: 'Child Epic 2', group: group, parent_id: parent_epic1.id, start_date: end_of_quarter - 17.days, end_date: end_of_quarter - 6.days) }

      let!(:parent_epic2) { create(:epic, title: 'Parent Epic 2', group: group, start_date: end_of_quarter - 14.days, end_date: end_of_quarter - 4.days) }
      let!(:child_epic3) { create(:epic, title: 'Child Epic 3', group: group, parent_id: parent_epic2.id, end_date: end_of_quarter - 4.days) }
      let!(:child_epic4) { create(:epic, title: 'Child Epic 4', group: group, parent_id: parent_epic2.id, end_date: end_of_quarter - 6.days) }

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

          expand_epic_at(2)

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

      it 'renders the epics with start_date_asc if current sort is incorrect' do
        visit group_roadmap_path(group, sort: 'INCORRECT_VALUE')
        expect(page).to have_current_path(/sort=start_date_asc/)
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
