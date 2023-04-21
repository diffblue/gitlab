# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update Epic', :js, feature_category: :portfolio_management do
  include DropzoneHelper

  let(:user) { create(:user) }

  let(:markdown) do
    <<-MARKDOWN.strip_heredoc
    This is a task list:

    - [ ] Incomplete entry 1
    - [ ] Incomplete entry 2
    MARKDOWN
  end

  before do
    stub_licensed_features(epics: true)

    sign_in(user)
  end

  context 'when user who is not a group member displays the epic' do
    let(:group) { create(:group, :public) }
    let(:epic) { create(:epic, group: group, description: markdown) }

    it 'does not show the Edit button' do
      visit group_epic_path(group, epic)

      expect(page).not_to have_selector('.js-issuable-edit')
    end
  end

  shared_examples 'updates epic' do
    before do
      group.add_developer(user)
      visit group_epic_path(group, epic)
      wait_for_requests
    end

    context 'update form' do
      before do
        find('.js-issuable-edit').click
      end

      it 'updates the epic' do
        fill_in 'issuable-title', with: 'New epic title'
        fill_in 'issue-description', with: 'New epic description'

        page.within('.detail-page-description') do
          click_link('Preview')
          expect(find('.md-preview-holder')).to have_content('New epic description')
        end

        click_button 'Save changes'

        expect(find('.issuable-details h1.title')).to have_content('New epic title')
        expect(find('.issuable-details .description')).to have_content('New epic description')
      end

      it 'updates the epic and keep the description saved across reload',
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/408227' do
        fill_in 'issue-description', with: 'New epic description'

        page.within('.detail-page-description') do
          click_link('Preview')
          expect(find('.md-preview-holder')).to have_content('New epic description')
        end

        visit group_epic_path(group, epic)

        # Deal with the beforeunload browser popup
        page.driver.browser.switch_to.alert.accept

        wait_for_requests
        find('.js-issuable-edit').click

        page.within('.detail-page-description') do
          click_link('Preview')
          expect(find('.md-preview-holder')).to have_content('New epic description')
        end
      end

      it 'creates a todo only for mentioned users' do
        mentioned = create(:user)

        # Add a trailing space to close mention auto-complete dialog, which might block the save button
        fill_in 'issue-description', with: "FYI #{mentioned.to_reference} "

        click_button 'Save changes'

        expect(find('.issuable-details h1.title')).to have_content('title')

        visit dashboard_todos_path

        expect(page).to have_selector('.todos-list .todo', count: 0)

        sign_in(mentioned)

        visit dashboard_todos_path

        page.within ".header-content span[aria-label='#{_('Todos count')}']" do
          expect(page).to have_content '1'
        end
        expect(page).to have_selector('.todos-list .todo', count: 1)
        within first('.todo') do
          expect(page).to have_content "#{epic.title} · #{epic.group.name} #{epic.to_reference}"
        end
      end

      it 'edits full screen' do
        page.within('.detail-page-description') { find('.js-zen-enter').click }

        expect(page).to have_selector('.div-dropzone-wrapper.fullscreen')
      end

      it 'uploads a file when dragging into textarea' do
        link_css = 'a.no-attachment-icon img.js-lazy-loaded[alt="banana_sample"]'
        link_match = %r{/groups/#{Regexp.escape(group.full_path)}/-/uploads/\h{32}/banana_sample\.gif\z}
        dropzone_file Rails.root.join('spec', 'fixtures', 'banana_sample.gif')

        expect(page.find_field("issue-description").value).to have_content('banana_sample')

        page.within('.detail-page-description') do
          click_link('Preview')
          wait_for_requests

          within('.md-preview-holder') do
            link = find(link_css)['src']
            expect(link).to match(link_match)
          end
        end

        click_button 'Save changes'
        wait_for_requests

        link = find(link_css)['src']
        expect(link).to match(link_match)
      end

      describe 'autocomplete enabled' do
        it 'opens atwho container' do
          find('#issue-description').native.send_keys('@')
          expect(page).to have_selector('.atwho-container')
        end
      end
    end

    context 'epic sidebar' do
      it 'opens datepicker when clicking Edit button' do
        page.within('.issuable-sidebar [data-testid="start-date"]') do
          click_button('Edit')
          expect(find('[data-testid="expanded-content"]')).to have_selector('.gl-datepicker')
          expect(find('[data-testid="expanded-content"]')).to have_selector('.gl-datepicker .pika-single.is-bound')
        end
      end
    end

    it 'updates the tasklist' do
      expect(page).to have_selector('ul.task-list',      count: 1)
      expect(page).to have_selector('li.task-list-item', count: 2)
      expect(page).to have_selector('ul input[checked]', count: 0)

      find('.task-list .task-list-item', text: 'Incomplete entry 1').find('input').click

      expect(page).to have_selector('ul input[checked]', count: 1)
    end

    it 'shows drag icons on hover of list item' do
      expect(page).to have_selector('.drag-icon', visible: false)

      first('li.task-list-item').hover

      expect(page).to have_selector('.drag-icon', visible: true)
    end
  end

  context 'when user with developer access displays the epic' do
    let_it_be(:group) { create(:group, :public) }

    let(:epic) { create(:epic, group: group, description: markdown) }

    it_behaves_like 'updates epic'
  end

  context 'when user with developer access displays the epic from a subgroup' do
    let_it_be(:parent_group) { create(:group, :public) }
    let_it_be(:group) { create(:group, parent: parent_group) }

    let(:epic) { create(:epic, group: group, description: markdown) }

    it_behaves_like 'updates epic'
  end
end
