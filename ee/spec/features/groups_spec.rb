# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group' do
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

    before do
      stub_ee_application_setting(should_check_namespace_plan: true)
      stub_ee_application_setting(enforce_namespace_storage_limit: true)

      group.root_storage_statistics.update!(
        storage_size: ::EE::Gitlab::Namespaces::Storage::Enforcement::FREE_NAMESPACE_STORAGE_CAP
      )
      group.add_maintainer(user)
      sign_in(user)
    end

    context 'with storage_enforcement_date set' do
      let_it_be(:storage_enforcement_date) { Date.today + 30 }

      before do
        allow_next_found_instance_of(Group) do |group|
          allow(group).to receive(:storage_enforcement_date).and_return(storage_enforcement_date)
        end
      end

      it 'displays the banner in the group page' do
        visit group_path(group)
        expect_page_to_have_storage_enforcement_banner(storage_enforcement_date)
      end

      it 'does not display the banner in a paid group page' do
        allow_next_found_instance_of(Group) do |group|
          allow(group).to receive(:paid?).and_return(true)
        end
        visit group_path(group)
        expect_page_not_to_have_storage_enforcement_banner
      end

      it 'does not display the banner if user has previously closed unless threshold has changed' do
        visit group_path(group)
        expect_page_to_have_storage_enforcement_banner(storage_enforcement_date)
        find('.js-storage-enforcement-banner [data-testid="close-icon"]').click
        wait_for_requests
        page.refresh
        expect_page_not_to_have_storage_enforcement_banner

        storage_enforcement_date = Date.today + 13
        allow_next_found_instance_of(Group) do |group|
          allow(group).to receive(:storage_enforcement_date).and_return(storage_enforcement_date)
        end
        page.refresh
        expect_page_to_have_storage_enforcement_banner(storage_enforcement_date)
      end
    end

    context 'with storage_enforcement_date not set' do
      before do
        allow_next_found_instance_of(Group) do |group|
          allow(group).to receive(:storage_enforcement_date).and_return(nil)
        end
      end

      it 'does not display the banner in the group page' do
        stub_feature_flags(namespace_storage_limit_bypass_date_check: false)
        visit group_path(group)
        expect_page_not_to_have_storage_enforcement_banner
      end
    end
  end

  def expect_page_to_have_storage_enforcement_banner(storage_enforcement_date)
    expect(page).to have_text "Effective #{storage_enforcement_date}, namespace storage limits will apply"
  end

  def expect_page_not_to_have_storage_enforcement_banner
    expect(page).not_to have_text "namespace storage limits will apply"
  end
end
