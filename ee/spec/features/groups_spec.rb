# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group', feature_category: :subgroups do
  include NamespaceStorageHelpers

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

  describe 'storage_enforcement_banner', :js do
    let_it_be_with_refind(:group) { create(:group, :with_root_storage_statistics) }
    let_it_be_with_refind(:user) { create(:user) }
    let_it_be(:storage_banner_text) { "A namespace storage limit will soon be enforced" }

    before do
      stub_ee_application_setting(should_check_namespace_plan: true)
      stub_ee_application_setting(enforce_namespace_storage_limit: true)
      set_used_storage(group, megabytes: 12)
      set_notification_limit(group, megabytes: 12)
      group.add_maintainer(user)
      sign_in(user)
    end

    context 'when the group is over the notification_limit' do
      it 'displays the banner in the group page' do
        visit group_path(group)
        expect(page).to have_text storage_banner_text
      end

      it 'does not display the dismissed banner if the group is still over notification_limit' do
        visit group_path(group)

        expect(page).to have_text storage_banner_text

        find('.js-storage-enforcement-banner [data-testid="close-icon"]').click
        page.refresh

        expect(page).not_to have_text storage_banner_text
      end

      context 'when the group does not reach the notification_limit' do
        before do
          set_notification_limit(group, megabytes: 13)
        end

        it 'does not display the banner' do
          visit group_path(group)
          expect(page).not_to have_text storage_banner_text
        end
      end
    end
  end
end
