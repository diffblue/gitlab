# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Protected Environments' do
  include Spec::Support::Helpers::ModalHelpers

  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, group: group) }
  let(:user) { create(:user) }
  let(:environments) { %w(production development staging test) }

  before do
    stub_licensed_features(protected_environments: true)

    environments.each do |environment_name|
      create(:environment, name: environment_name, project: project)
    end

    create(:protected_environment, project: project, name: 'production')
    create(:protected_environment, project: project, name: 'removed environment')
    create(:protected_environment, project: nil, group: group, name: 'staging')

    sign_in(user)
  end

  context 'logged in as developer' do
    before do
      project.add_developer(user)

      visit project_settings_ci_cd_path(project)
    end

    it 'does not have access to Protected Environments settings' do
      expect(page).to have_gitlab_http_status(:not_found)
    end
  end

  context 'logged in as a maintainer' do
    before do
      project.add_maintainer(user)
    end

    context 'with unified approval rules' do
      before do
        stub_feature_flags(multiple_environment_approval_rules_fe: false)
        visit project_settings_ci_cd_path(project)
      end

      it 'has access to Protected Environments settings' do
        expect(page).to have_gitlab_http_status(:ok)
      end

      it 'allows seeing a list of protected environments', :js do
        within('.protected-branches-list') do
          expect(page).to have_content('production')
          expect(page).to have_content('removed environment')
        end
      end

      it 'allows seeing a list of upstream protected environments', :js do
        within('.group-protected-branches-list') do
          expect(page).to have_content('staging')
        end
      end

      it 'allows creating explicit protected environments', :js do
        within('[data-testid="new-protected-environment"]') do
          set_protected_environment('staging')
          set_allowed_to_deploy('Developers + Maintainers')
          set_required_approvals(1)
          click_on('Protect')
        end

        wait_for_requests

        within('.protected-branches-list') do
          expect(page).to have_content('staging')

          within('tr', text: 'staging') do
            expect(page).to have_content('Developers + Maintainers')
            expect(page).to have_content('1')
          end
        end
      end

      it 'allows updating access to a protected environment', :js, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/11086' do
        within('.protected-branches-list tr', text: 'production') do
          set_allowed_to_deploy('Developers + Maintainers')
        end

        visit project_settings_ci_cd_path(project)

        within('.protected-branches-list') do
          expect(page).to have_content('1 role, 1 user')
        end
      end

      it 'allows unprotecting an environment', :js do
        within('.protected-branches-list tr', text: 'production') do
          click_on('Unprotect')
        end

        accept_gl_confirm

        wait_for_requests

        within('.protected-branches-list') do
          expect(page).not_to have_content('production')
        end
      end

      context 'when projects_tokens_optional_encryption feature flag is false' do
        before do
          stub_feature_flags(projects_tokens_optional_encryption: false)
        end

        context 'when runners_token exists but runners_token_encrypted is empty' do
          before do
            project.update_column(:runners_token, 'abc')
            project.update_column(:runners_token_encrypted, nil)
          end

          it 'shows setting page correctly' do
            visit project_settings_ci_cd_path(project)

            expect(page).to have_gitlab_http_status(:ok)
          end
        end
      end
    end

    context 'with multiple approval rules' do
      before do
        stub_feature_flags(multiple_environment_approval_rules_fe: true)
        visit project_settings_ci_cd_path(project)
      end

      it 'has access to Protected Environments settings' do
        expect(page).to have_gitlab_http_status(:ok)
      end

      it 'allows creating explicit protected environments', :js do
        within('[data-testid="new-protected-environment"]') do
          set_protected_environment('staging')
          set_allowed_to_approve('Developers + Maintainers')
          set_allowed_to_deploy('Developers + Maintainers')

          wait_for_requests

          set_required_approvals_for('Developers + Maintainers', 1)
          click_on('Protect')
        end

        wait_for_requests

        within('.protected-branches-list') do
          expect(page).to have_content('staging')

          within('tr', text: 'staging') do
            expect(page).to have_content('Developers + Maintainers')
            expect(page).to have_content('1')
          end
        end
      end
    end
  end

  def set_protected_environment(environment_name)
    click_button s_('ProtectedEnvironment|Select an environment')
    fill_in 'Search', with: environment_name
    wait_for_requests
    within '.gl-dropdown-contents' do
      find('.gl-dropdown-item', text: environment_name).click
    end
  end

  def set_allowed_to_deploy(option)
    button = within '[data-testid="create-deployer-dropdown"]' do
      find_button('Select users')
    end

    button.click

    find('.gl-dropdown-item', text: option).click

    button.click
  end

  def set_allowed_to_approve(option)
    button = within '[data-testid="create-approver-dropdown"]' do
      find_button('Select users')
    end

    button.click

    find('.gl-dropdown-item', text: option).click

    button.click
  end

  def set_required_approvals(number)
    within('#create-approval-count') do
      click_button '0'
    end

    within '.gl-dropdown-contents' do
      find('.gl-dropdown-item', text: number.to_s).click
    end
  end

  def set_required_approvals_for(option, number)
    within '[data-testid="approval-rules"]' do
      fill_in "approval-count-#{option}", with: number.to_s
    end
  end
end
