# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'epics list', :js do
  let(:group) { create(:group, :public) }
  let(:user) { create(:user) }
  let(:user_dev) { create(:user) }
  let!(:bug_label) { create(:group_label, group: group, title: 'Bug') }
  let!(:critical_label) { create(:group_label, group: group, title: 'Critical') }

  before do
    stub_licensed_features(epics: true)
    stub_feature_flags(unfiltered_epic_aggregates: false)
    stub_feature_flags(vue_epics_list: false)

    sign_in(user)
  end

  context 'when epics exist for the group' do
    let!(:epic1) { create(:epic, group: group, end_date: 10.days.ago) }
    let!(:epic2) { create(:epic, group: group, start_date: 2.days.ago) }
    let!(:epic3) { create(:epic, group: group, start_date: 10.days.ago, end_date: 5.days.ago) }

    before do
      visit group_epics_path(group)
    end

    it 'shows epics tabs for each status type' do
      page.within('.epics-state-filters') do
        expect(page).to have_selector('li > a#state-opened')
        expect(find('li > a#state-opened')[:title]).to eq('Filter by epics that are currently open.')

        expect(page).to have_selector('li > a#state-closed')
        expect(find('li > a#state-closed')[:title]).to eq('Filter by epics that are currently closed.')

        expect(page).to have_selector('li > a#state-all')
        expect(find('li > a#state-all')[:title]).to eq('Show all epics.')
      end
    end

    it 'shows the epics in the navigation sidebar' do
      expect(first('.nav-sidebar  .active a .nav-item-name')).to have_content('Epics')
      expect(first('.nav-sidebar .active a .count')).to have_content('3')
    end

    it 'shows epic updated date and comment count' do
      page.within('.issuable-list') do
        page.within('li:nth-child(1) .issuable-meta') do
          expect(find('.issuable-updated-at')).to have_content('updated just now')
          expect(find('.issuable-comments')).to have_content('0')
        end
      end
    end

    it 'shows epic start and/or end dates when present' do
      page.within('.issuable-list') do
        expect(find("li[data-id='#{epic1.id}'] .issuable-info .issuable-dates")).to have_content("No start date – #{epic1.end_date.strftime('%b %d, %Y')}")
        expect(find("li[data-id='#{epic2.id}'] .issuable-info .issuable-dates")).to have_content("#{epic2.start_date.strftime('%b %d, %Y')} – No end date")
      end
    end

    it 'renders the filtered search bar correctly' do
      page.within('.content-wrapper .content') do
        expect(page).to have_css('.epics-filters')
      end
    end

    it 'sorts by created_at DESC by default' do
      expect(page).to have_button('Created date')

      page.within('.content-wrapper .content') do
        expect(find('.top-area')).to have_content('All 3')

        page.within('.issuable-list') do
          page.within('li:nth-child(1) .issuable-main-info') do
            expect(page).to have_content(epic3.title)
          end

          page.within('li:nth-child(2) .issuable-main-info') do
            expect(page).to have_content(epic2.title)
          end

          page.within('li:nth-child(3) .issuable-main-info') do
            expect(page).to have_content(epic1.title)
          end
        end
      end
    end

    it 'sorts by the selected value and stores the selection for epic list' do
      page.within('.epics-other-filters') do
        click_button 'Created date'
        sort_options = find('ul.dropdown-menu-sort li').all('a').collect(&:text)

        expect(sort_options[0]).to eq('Created date')
        expect(sort_options[1]).to eq('Updated date')
        expect(sort_options[2]).to eq('Start date')
        expect(sort_options[3]).to eq('Due date')

        click_link 'Updated date'
      end

      expect(page).to have_button('Updated date')

      page.within('.content-wrapper .content') do
        expect(find('.top-area')).to have_content('All 3')

        page.within('.issuable-list') do
          page.within('li:nth-child(1) .issuable-main-info') do
            expect(page).to have_content(epic3.title)
          end

          page.within('li:nth-child(2) .issuable-main-info') do
            expect(page).to have_content(epic2.title)
          end

          page.within('li:nth-child(3) .issuable-main-info') do
            expect(page).to have_content(epic1.title)
          end
        end
      end

      visit group_epics_path(group)

      expect(page).to have_button('Updated date')
    end

    it 'renders the epic detail correctly after clicking the link' do
      page.within('.content-wrapper .content .issuable-list') do
        click_link(epic1.title)
      end

      wait_for_requests

      expect(page.find('.issuable-details h2.title')).to have_content(epic1.title)
    end
  end

  context 'when closed epics exist for the group' do
    let!(:epic1) { create(:epic, :closed, group: group, end_date: 10.days.ago) }

    before do
      visit group_epics_path(group)
    end

    it 'shows epic status, updated date and comment count' do
      page.within('.epics-state-filters') do
        click_link 'Closed'
      end

      page.within('.issuable-list') do
        page.within('li:nth-child(1) .issuable-meta') do
          expect(find('.issuable-status')).to have_content('CLOSED')
          expect(find('.issuable-updated-at')).to have_content('updated just now')
          expect(find('.issuable-comments')).to have_content('0')
        end
      end
    end
  end

  context 'when no epics exist for the group' do
    before do
      visit group_epics_path(group)
    end

    it 'renders the empty list page' do
      within('#content-body') do
        expect(find('.empty-state h4'))
          .to have_content('Epics let you manage your portfolio of projects more efficiently and with less effort')
      end
    end

    it 'shows epics tabs for each status type' do
      page.within('.epics-state-filters') do
        expect(page).to have_selector('li > a#state-opened')
        expect(page).to have_selector('li > a#state-closed')
        expect(page).to have_selector('li > a#state-all')
      end
    end
  end

  context 'vue epics list' do
    available_tokens = %w[Author Label My-Reaction]

    before do
      stub_feature_flags(vue_epics_list: true)
    end

    describe 'within a group' do
      let!(:epic1) { create(:epic, group: group, start_date: '2020-12-15', end_date: '2021-1-15') }
      let!(:epic2) { create(:epic, group: group, start_date: '2020-12-15') }
      let!(:epic3) { create(:epic, group: group, end_date: '2021-1-15') }
      let!(:award_emoji_star) { create(:award_emoji, name: 'star', user: user, awardable: epic1) }

      shared_examples 'epic list' do
        it 'renders epics list', :aggregate_failures do
          page.within('.issuable-list-container') do
            expect(page).to have_selector('.gl-tabs')
            expect(page).to have_selector('.vue-filtered-search-bar-container')
            expect(page.find('.issuable-list')).to have_selector('li.issue', count: 3)
          end
        end

        it 'renders epics item with metadata', :aggregate_failures do
          page.within('.issuable-list .issue:first-of-type') do
            expect(page).to have_link(epic2.title)
            expect(page).to have_text("&#{epic2.iid}")
            expect(page).to have_text("created just now by #{epic2.author.name}")
          end
        end

        it 'renders epic item timeframe', :aggregate_failures do
          issues = page.all('.issue')

          expect(issues[0]).to have_text('Dec 15, 2020 – No due date')
          expect(issues[1]).to have_text('Dec 15, 2020 – Jan 15, 2021')
          expect(issues[2]).to have_text('No start date – Jan 15, 2021')
        end
      end

      context 'when signed in' do
        before do
          group.add_developer(user)
          group.add_developer(user_dev)
          visit group_epics_path(group)
          wait_for_requests
        end

        it 'renders epics list header actions', :aggregate_failures do
          page.within('.issuable-list-container .nav-controls') do
            expect(page).to have_button('Edit epics')
            expect(page).to have_link('New epic')
          end
        end

        it_behaves_like 'epic list'

        it_behaves_like 'filtered search bar', available_tokens

        it 'shows bulk editing sidebar with actions and labels select dropdown', :aggregate_failures do
          click_button 'Edit epics'

          page.within('.issuable-list-container aside.right-sidebar') do
            expect(page).to have_button('Update all', disabled: true)
            expect(page).to have_button('Cancel')

            expect(page).to have_selector('form#epics-list-bulk-edit')
            expect(page).to have_button('Label')
          end
        end

        it 'shows checkboxes for selecting epics while bulk editing sidebar is visible', :aggregate_failures do
          click_button 'Edit epics'

          page.within('.issuable-list-container') do
            expect(page).to have_selector('.vue-filtered-search-bar-container input[type="checkbox"]')
            expect(page.first('.issuable-list li.issue')).to have_selector('.gl-form-checkbox input[type="checkbox"]')
          end
        end

        it 'applies label to multiple epics from bulk editing sidebar', :aggregate_failures do
          # Vertify that no labels are applied already
          expect(find('.issuable-list li.issue .issuable-info', match: :first)).not_to have_selector('.gl-label')

          # Bulk edit all epics to apply label
          page.within('.issuable-list-container') do
            click_button 'Edit epics'

            page.within('.vue-filtered-search-bar-container') do
              page.find('input[type="checkbox"]').click
            end

            page.within('aside.right-sidebar') do
              click_button 'Label'

              wait_for_requests

              click_link bug_label.title
              click_button 'Update all'

              wait_for_requests
            end
          end

          # Verify that label is applied
          expect(find('.issuable-list li.issue .issuable-info', match: :first)).to have_selector('.gl-label', text: bug_label.title)
        end
      end

      context 'when signed out' do
        before do
          sign_out user
          visit group_epics_path(group)
          wait_for_requests
        end

        it_behaves_like 'epic list'
      end
    end

    describe 'within a sub-group group' do
      let!(:subgroup) { create(:group, parent: group, name: 'subgroup') }
      let!(:sub_epic1) { create(:epic, group: subgroup, start_date: '2020-12-15', end_date: '2021-1-15') }
      let!(:sub_epic2) { create(:epic, group: subgroup, start_date: '2020-12-15') }
      let!(:award_emoji_star) { create(:award_emoji, name: 'star', user: user, awardable: sub_epic1) }

      before do
        subgroup.add_developer(user)
        subgroup.add_developer(user_dev)
        visit group_epics_path(subgroup)
        wait_for_requests
      end

      it_behaves_like 'filtered search bar', available_tokens
    end
  end
end
