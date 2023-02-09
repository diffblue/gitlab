# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Registration group and project creation flow', :saas, :js, feature_category: :onboarding do
  let_it_be(:user) { create(:user) }

  let(:experiments) { {} }

  before do
    # https://gitlab.com/gitlab-org/gitlab/-/issues/340302
    allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(138)
    stub_experiments(experiments)
    sign_in(user)
    visit users_sign_up_welcome_path

    expect(page).to have_content('Welcome to GitLab') # rubocop:disable RSpec/ExpectInHook

    choose 'Just me'
    choose 'Create a new project'
    click_on 'Continue'
  end

  it 'A user can create a group and project' do
    page.within '.js-group-path-display' do
      expect(page).to have_content('{group}')
    end

    page.within '.js-project-path-display' do
      expect(page).to have_content('{project}')
    end

    fill_in 'group_name', with: 'test group'

    fill_in 'blank_project_name', with: 'test project'

    page.within '.js-group-path-display' do
      expect(page).to have_content('test-group')
    end

    page.within '.js-project-path-display' do
      expect(page).to have_content('test-project')
    end

    click_on 'Create project'

    expect(page).to have_content('Get started with GitLab Ready to get started with GitLab?')
  end

  it 'a user can create a group and import a project' do
    click_on 'Import'

    page.within '.js-import-group-path-display' do
      expect(page).to have_content('{group}')
    end

    click_on 'GitHub'

    page.within('.gl-field-error') do
      expect(page).to have_content('This field is required.')
    end

    fill_in 'import_group_name', with: 'test group'

    page.within '.js-import-group-path-display' do
      expect(page).to have_content('test-group')
    end

    click_on 'GitHub'

    expect(page).to have_content('To connect GitHub repositories, you first need to authorize GitLab to')
  end

  context 'with exiting onboarding' do
    it 'does not show a link to exit the page' do
      expect(page).not_to have_link('Exit.')
    end

    context 'when require_verification_for_namespace_creation experiment is enabled' do
      let(:experiments) do
        {
          require_verification_for_namespace_creation: :candidate
        }
      end

      it 'shows a link to exit the page and verification' do
        expect(page).to have_button('Verify your identity')
        expect(page).to have_link('Exit.', href: exit_users_sign_up_groups_projects_path)
        expect(page).to have_content('You can always verify your account at a later time to create a group.')
      end
    end
  end
end
