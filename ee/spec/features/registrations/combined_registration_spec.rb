# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Registration group and project creation flow', :saas, :js, feature_category: :onboarding do
  let_it_be(:user) { create(:user) }

  let(:experiments) { {} }

  before do
    # https://gitlab.com/gitlab-org/gitlab/-/issues/340302
    allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(148)
    stub_experiments(experiments)
    sign_in(user)
    visit users_sign_up_welcome_path

    expect(page).to have_content('Welcome to GitLab') # rubocop:disable RSpec/ExpectInHook

    choose 'Just me'
    choose 'Create a new project'
    click_on 'Continue'
  end

  it 'A user can create a group and project' do
    page.within('[data-testid="url-group-path"]') do
      expect(page).to have_content('{group}')
    end

    page.within('[data-testid="url-project-path"]') do
      expect(page).to have_content('{project}')
    end

    fill_in 'group_name', with: '@_'
    fill_in 'blank_project_name', with: 'test project'

    page.within('[data-testid="url-group-path"]') do
      expect(page).to have_content('_')
    end

    page.within('[data-testid="url-project-path"]') do
      expect(page).to have_content('test-project')
    end

    click_on 'Create project'

    expect_filled_form_and_error_message

    fill_in 'group_name', with: 'test group'

    page.within('[data-testid="url-group-path"]') do
      expect(page).to have_content('test-group')
    end

    click_on 'Create project'

    expect(page).to have_content('Get started with GitLab Ready to get started with GitLab?')
  end

  it 'a user can create a group and import a project' do
    click_on 'Import'

    page.within('[data-testid="url-group-path"]') do
      expect(page).to have_content('{group}')
    end

    click_on 'GitHub'

    page.within('.gl-field-error') do
      expect(page).to have_content('This field is required.')
    end

    fill_in 'import_group_name', with: 'test group'

    page.within('[data-testid="url-group-path"]') do
      expect(page).to have_content('test-group')
    end

    click_on 'GitHub'

    expect(page).to have_content('To connect GitHub repositories, you first need to authorize GitLab to')
  end

  def expect_filled_form_and_error_message
    expect(find('[data-testid="group-name"]').value).to eq('@_')
    expect(find('[data-testid="project-name"]').value).to eq('test project')

    page.within('#error_explanation') do
      expect(page).to have_content('The Group contains the following errors')
    end
  end
end
