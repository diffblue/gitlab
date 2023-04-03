# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Protected Environments', feature_category: :environment_management do
  include Spec::Support::Helpers::ModalHelpers
  include ListboxHelpers

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
      visit project_settings_ci_cd_path(project)
    end

    it 'allows set "Allow pipeline triggerer to approve deployment"' do
      expect(page.find('#project_allow_pipeline_trigger_approve_deployment')).not_to be_checked
      within('#js-protected-environments-settings') do
        check('project_allow_pipeline_trigger_approve_deployment')
        click_on('Save changes')
      end

      wait_for_requests

      within('#js-protected-environments-settings') do
        expect(page.find('#project_allow_pipeline_trigger_approve_deployment')).to be_checked
      end
    end

    context 'with protected environments' do
      it 'has access to Protected Environments settings' do
        expect(page).to have_gitlab_http_status(:ok)
      end

      it 'allows creating explicit protected environments', :js do
        within('[data-testid="new-protected-environment"]') do
          set_protected_environment('staging')
          set_allowed_to_deploy('Developers + Maintainers')
          set_allowed_to_approve('Developers + Maintainers')

          wait_for_requests

          set_required_approvals_for('Developers + Maintainers', 1)

          click_on('Protect')
        end

        wait_for_requests

        within_protected_environments_list do
          expect(page).to have_content('staging')

          click_button 'staging'

          within_deployers do
            expect(page).to have_content('Developers + Maintainers')
          end

          within_approvers do
            expect(page).to have_content('Developers + Maintainers')
            expect(page).to have_content('1')
          end
        end
      end

      it 'allows seeing a list of protected environments', :js do
        within_protected_environments_list do
          expect(page).to have_button('production')
          expect(page).to have_button('removed environment')
        end
      end

      it 'allows seeing a list of upstream protected environments', :js do
        within('.group-protected-branches-list') do
          expect(page).to have_content('staging')
        end
      end

      it 'allows updating access to a protected environment', :js do
        within_protected_environments_list do
          click_button 'production'
          click_button 'Add deployment rules'
        end

        set_allowed_to_deploy('Developers + Maintainers')

        click_button _('Save')

        wait_for_requests

        visit project_settings_ci_cd_path(project)

        within_protected_environments_list do
          expect(page).to have_content('2 Deployment Rules')
        end
      end

      it 'allows unprotecting an environment', :js do
        within_protected_environments_list do
          click_button 'production'
          click_button s_('ProtectedEnvironments|Unprotect')
        end

        accept_gl_confirm

        wait_for_requests

        within_protected_environments_list do
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
  end

  def set_protected_environment(environment_name)
    click_button s_('ProtectedEnvironment|Select an environment')
    fill_in 'Search', with: environment_name
    wait_for_requests
    select_listbox_item(environment_name)
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

  def set_required_approvals_for(option, number)
    within '[data-testid="approval-rules"]' do
      fill_in "approval-count-#{option}", with: number.to_s
    end
  end

  def within_protected_environments_list(&block)
    within('[data-testid="protected-environments-list"]', &block)
  end

  def within_deployers(&block)
    within('[data-testid="protected-environment-staging-deployers"]', &block)
  end

  def within_approvers(&block)
    within('[data-testid="protected-environment-staging-approvers"]', &block)
  end
end
