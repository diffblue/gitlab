# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'group epic roadmap', :js do
  include FilteredSearchHelpers
  include MobileHelpers

  let(:user) { create(:user) }
  let(:user_dev) { create(:user) }
  let(:group) { create(:group) }
  let(:milestone) { create(:milestone, group: group) }
  let(:state_dropdown) { find('.dropdown-epics-state') }

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

  before do
    stub_licensed_features(epics: true)
    stub_feature_flags(unfiltered_epic_aggregates: false)
    stub_feature_flags(roadmap_daterange_filter: false)

    sign_in(user)
  end

  context 'when epics exist for the group' do
    available_tokens = %w[Author Label Milestone Epic My-Reaction]

    let!(:epic_with_bug) { create(:labeled_epic, group: group, start_date: 10.days.ago, end_date: 1.day.ago, labels: [bug_label]) }
    let!(:epic_with_critical) { create(:labeled_epic, group: group, start_date: 20.days.ago, end_date: 2.days.ago, labels: [critical_label]) }
    let!(:closed_epic) { create(:epic, :closed, group: group, start_date: 20.days.ago, end_date: 2.days.ago) }

    before do
      visit group_roadmap_path(group)
      wait_for_requests
    end

    describe 'roadmap page' do
      it 'renders roadmap preset buttons correctly' do
        page.within('.gl-segmented-control') do
          expect(page).to have_css('input[value="QUARTERS"]')
          expect(page).to have_css('input[value="MONTHS"]')
          expect(page).to have_css('input[value="WEEKS"]')
        end
      end

      it 'renders the filtered search bar correctly' do
        page.within('.content-wrapper .content .epics-filters') do
          expect(page).to have_css('.vue-filtered-search-bar-container')
        end
      end

      it 'renders the sort dropdown correctly' do
        page.within('.vue-filtered-search-bar-container') do
          expect(page).to have_css('.sort-dropdown-container')
          find('.sort-dropdown-container .dropdown-toggle').click
          page.within('.sort-dropdown-container .dropdown-menu') do
            expect(page).to have_selector('li button', count: 2)
            expect(page).to have_content('Start date')
            expect(page).to have_content('Due date')
          end
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

      it 'saves last selected epic state', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/341827' do
        state_dropdown.find('button', text: 'Open epics').click

        wait_for_all_requests
        visit group_roadmap_path(group)
        wait_for_requests

        expect(state_dropdown.find('.dropdown-toggle')).to have_text("Open epics")
        page.within('.roadmap-container .epics-list-section') do
          expect(page).to have_selector('.epics-list-item .epic-title', count: 2)
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

      it 'keeps label filter when filtering by state' do
        state_dropdown.find('.dropdown-toggle').click
        state_dropdown.find('button', text: 'Open epics').click

        page.within('.roadmap-container .epics-list-section') do
          expect(page).to have_selector('.epics-list-item .epic-title', count: 1)
          expect(page).to have_content(epic_with_bug.title)
        end
      end
    end

    describe 'filtered search tokens' do
      let!(:epic1) { create(:epic, group: group, end_date: 10.days.ago) }
      let!(:epic2) { create(:epic, group: group, start_date: 2.days.ago) }
      let!(:award_emoji_star) { create(:award_emoji, name: 'star', user: user, awardable: epic1) }

      before do
        group.add_developer(user_dev)
        visit group_roadmap_path(group)
        wait_for_requests
      end

      it_behaves_like 'filtered search bar', available_tokens
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

      it_behaves_like 'filtered search bar', available_tokens
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

  context 'when over 1000 epics match roadmap filters' do
    before do
      create_list(:epic, 2, group: group, start_date: 10.days.ago, end_date: 1.day.ago)
      visit group_roadmap_path(group)

      execute_script("gon.roadmap_epics_limit = 1;")
    end

    describe 'roadmap page' do
      it 'renders warning callout banner' do
        page.within('.content-wrapper .content') do
          expect(page).to have_selector('[data-testid="epics_limit_callout"]', count: 1)
          expect(find('[data-testid="epics_limit_callout"]')).to have_content 'Some of your epics might not be visible Roadmaps can display up to 1,000 epics. These appear in your selected sort order.'
        end

        page.within('[data-testid="epics_limit_callout"]') do
          expect(find_link('Learn more')[:href]).to eq("https://docs.gitlab.com/ee/user/group/roadmap/")
        end
      end

      it 'is removed after dismissal and even after reload' do
        page.within('[data-testid="epics_limit_callout"]') do
          find('.gl-dismiss-btn').click
        end

        expect(page).not_to have_selector('[data-testid="epics_limit_callout"]')

        refresh

        expect(page).not_to have_selector('[data-testid="epics_limit_callout"]')
      end
    end
  end
end
