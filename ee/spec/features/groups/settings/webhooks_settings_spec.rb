# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Settings > Group Hooks', feature_category: :integrations do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:webhooks_path) { group_hooks_path(group) }

  before_all do
    group.add_owner(user)
  end

  before do
    sign_in(user)
  end

  context 'for developer' do
    before_all do
      group.add_developer(user)
    end

    it 'to be disallowed to view' do
      visit webhooks_path

      expect(page.status_code).to eq(404)
    end
  end

  context 'for maintainer' do
    before_all do
      group.add_maintainer(user)
    end

    it 'to be disallowed to view' do
      visit webhooks_path

      expect(page.status_code).to eq(404)
    end
  end

  context 'for owner' do
    context 'when accessing group hooks' do
      let_it_be(:hook) { create(:group_hook, :all_events_enabled, enable_ssl_verification: true, group: group) }

      let(:url) { generate(:url) }

      it 'shows a list of available group hook triggers' do
        visit webhooks_path

        expect(page.status_code).to eq(200)
        expect(page).to have_content(hook.url)
        expect(page).to have_content('SSL Verification: enabled')
        expect(page).to have_content('Push events')
        expect(page).to have_content('Tag push events')
        expect(page).to have_content('Comments')
        expect(page).to have_content('Confidential comments')
        expect(page).to have_content('Issues events')
        expect(page).to have_content('Confidential issues events')
        expect(page).to have_content('Member events')
        expect(page).to have_content('Subgroup events')
        expect(page).to have_content('Merge request events')
        expect(page).to have_content('Job events')
        expect(page).to have_content('Pipeline events')
        expect(page).to have_content('Wiki page events')
        expect(page).to have_content('Deployment events')
        expect(page).to have_content('Feature flag events')
        expect(page).to have_content('Releases events')
      end

      it 'creates a group hook', :js do
        visit webhooks_path

        fill_in 'URL', with: url
        check 'Tag push events'
        check 'Enable SSL verification'
        check 'Job events'

        expect { click_button 'Add webhook' }.to change { GroupHook.count }.by(1)

        expect(page).to have_content(url)
        expect(page).to have_content('SSL Verification: enabled')
        expect(page).to have_content('Tag push events')
        expect(page).to have_content('Job events')
        expect(page).to have_content('Push events')
      end

      it 'edits an existing group hook', :js do
        visit webhooks_path

        click_link 'Edit'
        fill_in 'URL', with: url
        check 'Enable SSL verification'
        click_button 'Save changes'

        expect(page).to have_content('Enable SSL verification')
        expect(page).to have_content('Recent events')
      end

      it 'tests an existing group hook', :js do
        create(:project, :repository, namespace: group)
        WebMock.stub_request(:post, hook.url)
        visit webhooks_path

        click_button 'Test'
        click_link 'Push events'

        expect(WebMock).to have_requested(:post, hook.url)
        expect(page).to have_current_path(webhooks_path, ignore_query: true)
        expect(page).to have_content 'Hook executed successfully'
      end

      it 'fails testing when there is no project with commits', :js do
        visit webhooks_path

        click_button 'Test'
        click_link 'Push events'

        expect(page).to have_current_path(webhooks_path, ignore_query: true)
        expect(page).to have_content 'Hook execution failed'
      end

      context 'when deleting existing group hook' do
        it 'deletes the group hook from the group hooks page' do
          visit webhooks_path

          expect { click_link 'Delete' }.to change { GroupHook.count }.by(-1)
        end

        it 'deletes the group hook from the edit group hook page' do
          visit webhooks_path
          click_link 'Edit'

          expect { click_link 'Delete' }.to change { GroupHook.count }.by(-1)
        end
      end
    end

    context 'when accessing group hook logs' do
      let_it_be(:hook) { create(:group_hook, group: group) }
      let_it_be(:hook_log) { create(:web_hook_log, web_hook: hook, internal_error_message: 'some error') }

      it 'shows a list of hook logs' do
        visit edit_group_hook_path(group, hook)

        expect(page).to have_content('Recent events')
        expect(page).to have_link('View details', href: hook_log.present.details_path)
      end

      it 'shows hook log details' do
        visit edit_group_hook_path(group, hook)
        click_link 'View details'

        expect(page).to have_content("POST #{hook_log.url}")
        expect(page).to have_content(hook_log.internal_error_message)
        expect(page).to have_content('Resend Request')
      end

      it 'retries the hook log' do
        WebMock.stub_request(:post, hook.url)

        visit edit_group_hook_path(group, hook)
        click_link 'View details'
        click_link 'Resend Request'

        expect(WebMock).to have_requested(:post, hook.url)
        expect(page).to have_current_path(edit_group_hook_path(group, hook), ignore_query: true)
      end

      it 'does not show search settings on the hook log details' do
        visit group_hook_hook_log_path(group, hook, hook_log)

        expect(page).not_to have_field(placeholder: 'Search settings', disabled: true)
      end
    end
  end
end
