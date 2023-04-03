# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Namespace user cap reached alert', :feature, :js, :use_clean_rails_memory_store_caching,
feature_category: :seat_cost_management do
  include ReactiveCachingHelpers

  let_it_be(:group, refind: true) do
    create(:group, :public,
           namespace_settings: create(:namespace_settings, new_user_signups_cap: 2))
  end

  let_it_be(:subgroup, refind: true) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, namespace: subgroup) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:subgroup_owner) { create(:user) }

  before_all do
    group.add_owner(owner)
    group.add_developer(developer)
    subgroup.add_owner(subgroup_owner)
  end

  context 'with an exceeded user cap' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)

      stub_cache(group)
    end

    it 'displays the banner to a group owner' do
      sign_in(owner)
      visit group_path(group)

      expect_group_page_for(group)
      expect_banner_to_be_present
    end

    it 'displays the banner to a group owner on a subgroup page' do
      sign_in(owner)
      visit group_path(subgroup)

      expect_group_page_for(subgroup)
      expect_banner_to_be_present
    end

    it 'displays the banner to a group owner on a project page' do
      sign_in(owner)
      visit project_path(project)

      expect_project_page_for(project)
      expect_banner_to_be_present
    end

    it 'does not display the banner when the feature flag is off' do
      stub_feature_flags(saas_user_caps: false)
      sign_in(owner)
      visit group_path(group)

      expect_group_page_for(group)
      expect_banner_to_be_absent
    end

    it 'does not display the banner to a user who is not a group owner' do
      sign_in(developer)
      visit group_path(group)

      expect_group_page_for(group)
      expect_banner_to_be_absent
    end

    it 'does not display the banner to a user who owns a subgroup' do
      sign_in(subgroup_owner)
      visit group_path(subgroup)

      expect_group_page_for(subgroup)
      expect_banner_to_be_absent
    end

    it 'does not display the banner to an unauthenticated user' do
      visit group_path(group)

      expect_group_page_for(group)
      expect_banner_to_be_absent
    end

    it 'does not display on pending members page' do
      sign_in(owner)
      visit pending_members_group_usage_quotas_path(group)

      expect_banner_to_be_absent
    end

    it 'can be dismissed' do
      sign_in(owner)
      visit group_path(group)
      dismiss_button.click

      expect_group_page_for(group)
      expect_banner_to_be_absent
    end

    it 'remains dismissed' do
      sign_in(owner)
      visit group_path(group)
      dismiss_button.click

      visit group_path(group)

      expect_group_page_for(group)
      expect_banner_to_be_absent
    end

    it 'is dismissed independently for each root group' do
      other_group = create(:group, :public,
                           namespace_settings: create(:namespace_settings, new_user_signups_cap: 1))
      other_group.add_owner(owner)
      stub_cache(other_group)
      sign_in(owner)
      visit group_path(group)
      dismiss_button.click

      visit group_path(other_group)

      expect_group_page_for(other_group)
      expect_banner_to_be_present
    end

    it 'is dismissed for a root group when dismissed from a subgroup' do
      sign_in(owner)
      visit group_path(subgroup)
      dismiss_button.click

      visit group_path(group)

      expect_group_page_for(group)
      expect_banner_to_be_absent
    end

    it 'does not display the banner to a group owner on a reactive cache miss' do
      stub_reactive_cache(group, nil)
      sign_in(owner)
      visit group_path(group)

      expect_group_page_for(group)
      expect_banner_to_be_absent
    end
  end

  context 'with a user cap that has not been exceeded' do
    before do
      group.namespace_settings.update!(new_user_signups_cap: 4)
      stub_cache(group)
    end

    it 'does not display the banner to a group owner' do
      sign_in(owner)
      visit group_path(group)

      expect_group_page_for(group)
      expect_banner_to_be_absent
    end
  end

  context 'without a user cap set' do
    before do
      group.namespace_settings.update!(new_user_signups_cap: nil)
      stub_cache(group)
    end

    it 'does not display the banner to a group owner' do
      sign_in(owner)
      visit group_path(group)

      expect_group_page_for(group)
      expect_banner_to_be_absent
    end
  end

  context 'with a user namespace' do
    it 'renders the page without a banner' do
      personal_project = create(:project, namespace: owner.namespace)

      sign_in(owner)
      visit project_path(personal_project)

      expect_project_page_for(personal_project)
      expect_banner_to_be_absent
    end
  end

  def dismiss_button
    find('button[data-testid="namespace_user_cap_alert_dismiss"]')
  end

  def expect_group_page_for(group)
    expect(page).to have_text group.name
    expect(page).to have_text "Group ID: #{group.id}"
  end

  def expect_project_page_for(project)
    expect(page).to have_text project.namespace.name
    expect(page).to have_text project.name
  end

  def expect_banner_to_be_present
    expect(page).to have_text 'Your group has reached its billable member limit'
  end

  def expect_banner_to_be_absent
    expect(page).not_to have_text 'Your group has reached its billable member limit'
  end

  def stub_cache(group)
    group_with_fresh_memoization = Group.find(group.id)
    result = group_with_fresh_memoization.calculate_reactive_cache
    stub_reactive_cache(group, result)
  end
end
