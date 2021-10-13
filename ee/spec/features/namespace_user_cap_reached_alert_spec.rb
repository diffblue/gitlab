# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Namespace user cap reached alert', :feature, :js do
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
    it 'displays the banner to a group owner' do
      sign_in(owner)
      visit group_path(group)

      expect(page).to have_text 'Your group has reached its billable member limit'
    end

    it 'displays the banner to a group owner on a subgroup page' do
      sign_in(owner)
      visit group_path(subgroup)

      expect(page).to have_text 'Your group has reached its billable member limit'
    end

    it 'displays the banner to a group owner on a project page' do
      sign_in(owner)
      visit project_path(project)

      expect(page).to have_text 'Your group has reached its billable member limit'
    end

    it 'does not display the banner when the feature flag is off' do
      stub_feature_flags(saas_user_caps: false)
      sign_in(owner)
      visit group_path(group)

      expect_banner_to_be_absent(group)
    end

    it 'does not display the banner to a user who is not a group owner' do
      sign_in(developer)
      visit group_path(group)

      expect_banner_to_be_absent(group)
    end

    it 'does not display the banner to a user who owns a subgroup' do
      sign_in(subgroup_owner)
      visit group_path(subgroup)

      expect_banner_to_be_absent(subgroup)
    end

    it 'does not display the banner to an unauthenticated user' do
      visit group_path(group)

      expect_banner_to_be_absent(group)
    end
  end

  context 'with a user cap that has not been exceeded' do
    before do
      group.namespace_settings.update!(new_user_signups_cap: 4)
    end

    it 'does not display the banner to a group owner' do
      sign_in(owner)
      visit group_path(group)

      expect_banner_to_be_absent(group)
    end
  end

  context 'without a user cap set' do
    before do
      group.namespace_settings.update!(new_user_signups_cap: nil)
    end

    it 'does not display the banner to a group owner' do
      sign_in(owner)
      visit group_path(group)

      expect_banner_to_be_absent(group)
    end
  end

  context 'with a user namespace' do
    it 'renders the page without a banner' do
      personal_project = create(:project, namespace: owner.namespace)

      sign_in(owner)
      visit project_path(personal_project)

      expect(page).to have_text owner.name
      expect(page).to have_text personal_project.name
      expect(page).not_to have_text 'Your group has reached its billable member limit'
    end
  end

  def expect_banner_to_be_absent(group)
    expect(page).to have_text group.name
    expect(page).to have_text "Group ID: #{group.id}"
    expect(page).not_to have_text 'Your group has reached its billable member limit'
  end
end
