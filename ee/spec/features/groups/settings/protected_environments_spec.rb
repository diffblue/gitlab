# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Protected Environments', :js, feature_category: :environment_management do
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

    within('.js-protected-environments-list') do
      expect(page).to have_content('staging')
      click_button('1 group')

      within('.gl-dropdown-contents li:nth-child(2)') do
        expect(page).to have_selector('.gl-dropdown-item-check-icon', visible: true)
        expect(page).to have_content('operator-group')
      end
      within('.gl-dropdown-contents li:nth-child(3)') do
        expect(page).to have_selector('.gl-dropdown-item-check-icon', visible: false)
        expect(page).to have_content('developer-group')
      end
    end
  end

  context 'when no subgroups exist' do
    let(:public_organization) { create(:group) }

    before do
      public_organization.add_owner(current_user)
    end

    it 'shows search box without throwing an error' do
      visit group_settings_ci_cd_path(public_organization)

      click_button('Select groups')

      within('.gl-dropdown-inner') { find('.gl-search-box-by-type') }
    end
  end

  context 'when protected environments already exist' do
    before do
      deploy_access_level = build(:protected_environment_deploy_access_level, group: operator_group)

      create(:protected_environment, :group_level, name: 'production', group: organization,
                                                   deploy_access_levels: [deploy_access_level])

      visit group_settings_ci_cd_path(organization)
    end

    it 'allows user to change the allowed groups' do
      within('.js-protected-environments-list') do
        expect(page).to have_content('production')
        click_button('1 group')

        within('.gl-dropdown-contents') do
          click_button('operator-group')                  # Unselect operator-group
          click_button('developer-group')                 # Select developer-group
        end

        find('.js-protected-environment-edit-form').click # Close the access level dropdown to update
      end

      visit group_settings_ci_cd_path(organization)       # Reload

      within('.js-protected-environments-list') do
        expect(page).to have_content('production')
        click_button('1 group')

        within('.gl-dropdown-contents li:nth-child(2)') do
          expect(page).to have_selector('.gl-dropdown-item-check-icon', visible: false)
          expect(page).to have_content('operator-group')
        end
        within('.gl-dropdown-contents li:nth-child(3)') do
          expect(page).to have_selector('.gl-dropdown-item-check-icon', visible: true)
          expect(page).to have_content('developer-group')
        end
      end
    end

    it 'allows user to destroy the entry' do
      within('.js-protected-environment-edit-form') do
        click_on('Unprotect')
      end

      find('.js-modal-action-primary').click

      within('.js-protected-environments-list') do
        expect(page).not_to have_content('production')
      end
    end
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

  context 'when the user has maintainer role' do
    let(:current_user) { organization_maintainer }

    it 'does not show the Protected Environments settings' do
      expect(page).not_to have_selector(".protected-environments-settings")
    end
  end
end
