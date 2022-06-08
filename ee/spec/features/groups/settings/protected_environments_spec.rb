# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Protected Environments', :js do
  let_it_be_with_refind(:organization) { create(:group, :private) }
  let_it_be(:developer_group) { create(:group, :private, name: 'developer-group', parent: organization) }
  let_it_be(:operator_group) { create(:group, :private, name: 'operator-group', parent: organization) }
  let_it_be(:unrelated_group) { create(:group) }
  let_it_be(:organization_owner) { create(:user).tap { |u| organization.add_owner(u) } }
  let_it_be(:organization_maintainer) { create(:user).tap { |u| organization.add_maintainer(u) } }

  let(:current_user) { organization_owner }

  before do
    stub_licensed_features(protected_environments: true)
    sign_in(current_user)

    visit group_settings_ci_cd_path(organization)
  end

  it 'shows Protected Environments settings' do
    expect(page).to have_selector(".protected-environments-settings")
  end

  it 'shows all subgroups of the organization in the creation form' do
    within('.js-new-protected-environment') do
      click_button('Select groups')

      expect(page).to have_content(developer_group.name)
      expect(page).to have_content(operator_group.name)
      expect(page).not_to have_content(unrelated_group.name)
    end
  end

  it 'allows to create a group-level protected environment' do
    within('.js-new-protected-environment') do
      select('staging')
      click_button('Select groups')
      click_button('operator-group')
      find('#allowed-users-label').click # Close the access level dropdown
      click_on('Protect')
    end

    wait_for_requests

    # TODO: When the editable list view is added, replace these internal data assertions by frontend component matching.
    created_protected_environment = organization.reload.protected_environments.first
    expect(organization.protected_environments.count).to eq(1)
    expect(created_protected_environment.name).to eq('staging')
    expect(created_protected_environment.deploy_access_levels.map(&:group)).to contain_exactly(operator_group)
  end

  context 'when license does not exist' do
    before do
      stub_licensed_features(protected_environments: false)

      visit group_settings_ci_cd_path(organization)
    end

    it 'does not show the Protected Environments settings' do
      expect(page).not_to have_selector(".protected-environments-settings")
    end
  end

  context 'when group_level_protected_environment feature flag is disabled' do
    before do
      stub_feature_flags(group_level_protected_environment: false)

      visit group_settings_ci_cd_path(organization)
    end

    it 'does not show the Protected Environments settings' do
      expect(page).not_to have_selector(".protected-environments-settings")
    end
  end

  context 'when the user has maintainer role' do
    let(:current_user) { organization_maintainer }

    it 'does not show the Protected Environments settings' do
      expect(page).not_to have_selector(".protected-environments-settings")
    end
  end
end
