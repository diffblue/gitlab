# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group', feature_category: :groups_and_projects do
  include NamespaceStorageHelpers
  include FreeUserCapHelpers

  describe 'group edit', :js do
    let_it_be(:user) { create(:user) }

    let_it_be(:group) do
      create(:group, :public).tap do |g|
        g.add_owner(user)
      end
    end

    let(:path) { edit_group_path(group, anchor: 'js-permissions-settings') }
    let(:group_wiki_licensed_feature) { true }

    before do
      stub_licensed_features(group_wikis: group_wiki_licensed_feature)

      sign_in(user)

      visit path
    end

    context 'when licensed feature group wikis is not enabled' do
      let(:group_wiki_licensed_feature) { false }

      it 'does not show the wiki settings menu' do
        expect(page).not_to have_content('Group-level wiki is disabled.')
      end
    end

    context 'wiki_access_level setting' do
      it 'saves new settings', :aggregate_failures do
        expect(page).to have_content('Group-level wiki is disabled.')

        [Featurable::PRIVATE, Featurable::DISABLED, Featurable::ENABLED].each do |wiki_access_level|
          find(
            ".js-general-permissions-form "\
              "#group_group_feature_attributes_wiki_access_level_#{wiki_access_level}").click

          click_button 'Save changes'

          expect(page).to have_content 'successfully updated'
          expect(group.reload.group_feature.wiki_access_level).to eq wiki_access_level
        end
      end
    end
  end

  describe 'storage pre-enforcement alert', :js do
    let_it_be_with_refind(:group) { create(:group, :with_root_storage_statistics) }
    let_it_be_with_refind(:user) { create(:user) }
    let_it_be(:storage_banner_text) { "A namespace storage limit will soon be enforced" }

    before do
      stub_ee_application_setting(should_check_namespace_plan: true, automatic_purchased_storage_allocation: true)
      set_used_storage(group, megabytes: 13)
      set_notification_limit(group, megabytes: 12)
      group.add_guest(user)
      sign_in(user)
    end

    context 'when the group is over the notification_limit' do
      it 'displays the alert in the group page' do
        visit group_path(group)
        expect(page).to have_text storage_banner_text
      end

      it 'does not display the dismissed alert if the group is still over notification_limit' do
        visit group_path(group)

        expect(page).to have_text storage_banner_text

        find('.js-storage-pre-enforcement-alert [data-testid="close-icon"]').click
        page.refresh

        expect(page).not_to have_text storage_banner_text
      end

      context 'when the group does not reach the notification_limit' do
        before do
          set_notification_limit(group, megabytes: 13)
        end

        it 'does not display the alert' do
          visit group_path(group)
          expect(page).not_to have_text storage_banner_text
        end
      end
    end
  end

  describe 'combined storage and users pre-enforcement alert', :saas do
    let_it_be_with_refind(:group) do
      create(:group_with_plan, :with_root_storage_statistics, :private, plan: :free_plan,
        name: 'over_storage_and_users')
    end

    let_it_be_with_refind(:user) { create(:user) }
    let(:alert) do
      'Your Free top-level group, over_storage_and_users, has more than 5 users and uses more than 5 GiB of data'
    end

    before do
      set_notification_limit(group, megabytes: 10_000)
      set_dashboard_limit(group, megabytes: 5_000)
      stub_ee_application_setting(should_check_namespace_plan: true, automatic_purchased_storage_allocation: true)
    end

    context 'when owner' do
      before do
        group.add_owner(user)
        sign_in(user)
        exceed_user_cap(group)
        enforce_free_user_caps
      end

      context 'when the group is over both storage notification and users limits' do
        before do
          set_used_storage(group, megabytes: 11_000)
        end

        it 'displays the alert with CTAs' do
          visit group_path(group)

          expect(page).to have_text alert
          expect(page).to have_text 'Explore paid plans'
          expect(page).to have_text 'Manage usage'
        end
      end

      context 'when the group is not over one of the limits' do
        before do
          set_used_storage(group, megabytes: 9_000)
        end

        it 'does not display the alert' do
          visit group_path(group)

          expect(page).not_to have_text alert
        end
      end
    end

    context 'when non owner' do
      before do
        group.add_maintainer(user)
        sign_in(user)
        exceed_user_cap(group)
        enforce_free_user_caps
      end

      context 'when the group is over both storage notification and users limits' do
        before do
          set_used_storage(group, megabytes: 11_000)
        end

        it 'displays the alert without CTAs' do
          visit group_path(group)

          expect(page).to have_text alert
          expect(page).not_to have_text 'Explore paid plans'
          expect(page).not_to have_text 'Manage usage'
        end
      end

      context 'when the group is not over one of the limits' do
        before do
          set_used_storage(group, megabytes: 9_000)
        end

        it 'does not display the alert' do
          visit group_path(group)

          expect(page).not_to have_text alert
        end
      end
    end
  end
end
